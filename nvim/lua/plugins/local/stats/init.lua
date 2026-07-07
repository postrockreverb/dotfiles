local uv = vim.uv or vim.loop

local M = {}

-- How often (ms) accumulated time is persisted to the .nvim/stats file(s). A
-- forceful close (terminal tab killed without nvim shutting down gracefully)
-- loses at most this much data. A single coarse libuv timer means negligible
-- battery impact and no busy polling -- see notes at the bottom of this file.
local FLUSH_INTERVAL_MS = 60 * 1000

-- If a lock file is older than this (seconds) it is assumed stale (its holder
-- crashed) and stolen. Normal locks are held for microseconds.
local LOCK_STALE_S = 3

local state = {
  enabled = false,
  cwd = nil,
  -- every .nvim/stats found from cwd upward is tracked at once, so a session in
  -- a nested project counts toward that project AND its ancestors. Each target:
  --   { file = "<dir>/.nvim/stats", root = "<dir>", pending = { [date] = rec } }
  -- `pending` holds only THIS session's not-yet-persisted increments; on flush
  -- they are merged into the on-disk history under a lock, then cleared. We
  -- never write our own cumulative, so concurrent nvim instances sharing a file
  -- neither clobber each other's time nor double-count their own.
  targets = {},
  focused = true,
  seg_start = 0, -- uv.hrtime() (ns) at the last fold
  timer = nil,
}

local function today()
  return os.date("%Y-%m-%d")
end

local function day_rec(days, date)
  local rec = days[date]
  if not rec then
    rec = { focused = 0, unfocused = 0, sessions = 0 }
    days[date] = rec
  end
  return rec
end

local function read_data(file)
  local fd = uv.fs_open(file, "r", 420)
  if not fd then
    return {}
  end
  local stat = uv.fs_fstat(fd)
  local content = stat and uv.fs_read(fd, stat.size, 0) or ""
  uv.fs_close(fd)
  local ok, decoded = pcall(vim.json.decode, content)
  if not ok or type(decoded) ~= "table" or type(decoded.days) ~= "table" then
    return {}
  end
  local days = {}
  for date, rec in pairs(decoded.days) do
    if type(rec) == "table" then
      days[date] = {
        focused = tonumber(rec.focused) or 0,
        unfocused = tonumber(rec.unfocused) or 0,
        sessions = tonumber(rec.sessions) or 0,
      }
    end
  end
  return days
end

-- Run fn() while holding an exclusive lock for `file` (a sibling .lock created
-- with O_CREAT|O_EXCL). Returns true only if the lock was acquired AND fn ran
-- without error. Contention is resolved by a brief spin; a lock left behind by a
-- crashed process is stolen once it ages past LOCK_STALE_S.
local function with_lock(file, fn)
  local lock = file .. ".lock"
  local fd
  for _ = 1, 100 do
    fd = uv.fs_open(lock, "wx", 420)
    if fd then
      break
    end
    local st = uv.fs_stat(lock)
    if st and st.mtime and (os.time() - st.mtime.sec) >= LOCK_STALE_S then
      uv.fs_unlink(lock) -- steal a stale lock
    end
  end
  if not fd then
    return false
  end
  local ok = pcall(fn)
  uv.fs_close(fd)
  uv.fs_unlink(lock)
  return ok
end

-- Atomically replace `file` with the encoded days table (write temp + rename),
-- so a concurrent reader never observes a half-written file. Returns true on a
-- fully successful write.
local function write_atomic(file, days)
  local tmp = string.format("%s.tmp.%d", file, uv.os_getpid())
  local fd = uv.fs_open(tmp, "w", 420) -- 0644
  if not fd then
    return false
  end
  uv.fs_write(fd, vim.json.encode({ days = days, updated = os.time() }), 0)
  uv.fs_close(fd)
  if uv.fs_rename(tmp, file) then
    return true
  end
  uv.fs_unlink(tmp)
  return false
end

-- Add pending increments into `disk` exactly (in place). Used for the live
-- display, which is transient and wants the fractional seconds.
local function apply_pending(disk, pending)
  for date, p in pairs(pending) do
    local r = day_rec(disk, date)
    r.focused = r.focused + p.focused
    r.unfocused = r.unfocused + p.unfocused
    r.sessions = r.sessions + p.sessions
  end
end

-- Add pending increments into `disk` (in place) with stored seconds floored to
-- integers, returning the sub-second remainders to carry into the next flush so
-- repeated flooring never loses time. Used when persisting to disk.
local function merge_floored(disk, pending)
  local carry = {}
  for date, p in pairs(pending) do
    local r = day_rec(disk, date)
    local tf = r.focused + p.focused
    local tu = r.unfocused + p.unfocused
    r.focused = math.floor(tf)
    r.unfocused = math.floor(tu)
    r.sessions = r.sessions + p.sessions
    local rf, ru = tf - r.focused, tu - r.unfocused
    if rf > 0 or ru > 0 then
      carry[date] = { focused = rf, unfocused = ru, sessions = 0 }
    end
  end
  return carry
end

local function pending_empty(pending)
  for _, r in pairs(pending) do
    if r.focused > 0 or r.unfocused > 0 or r.sessions > 0 then
      return false
    end
  end
  return true
end

-- Build a tracking target: this session counts as +1 against today, held in
-- pending until the first successful flush merges it.
local function make_target(file, root)
  local pending = {}
  day_rec(pending, today()).sessions = 1
  return { file = file, root = root, pending = pending }
end

-- Collect every directory from cwd up to the filesystem root that has a
-- .nvim/stats file, nearest (cwd) first.
local function discover(cwd)
  local files = {}
  local dir = cwd
  while dir do
    local file = dir .. "/.nvim/stats"
    if uv.fs_stat(file) then
      files[#files + 1] = { file = file, root = dir }
    end
    local parent = vim.fs.dirname(dir)
    if not parent or parent == dir then
      break
    end
    dir = parent
  end
  return files
end

-- Fold the elapsed time of the current segment into today's PENDING bucket of
-- every tracked target, then reset the segment start. Time is attributed to the
-- date at fold time, so a session crossing midnight splits across days (accurate
-- to within one flush interval).
--
-- uv.hrtime() is monotonic but, on macOS, is backed by mach_continuous_time(),
-- which keeps advancing while the machine is asleep -- so the raw delta DOES
-- include suspend time. Guard against that: while nvim is actually running the
-- flush timer folds at least once per flush interval, so a segment much longer
-- than that interval means the process was frozen (system sleep/suspend, or a
-- long event-loop stall) rather than real editing. Such segments are dropped.
local function fold()
  local now = uv.hrtime()
  local delta = (now - state.seg_start) / 1e9 -- seconds
  local max_s = (state.interval / 1000) * 2 -- generous margin over one interval
  if delta > 0 and delta <= max_s then
    local date = today()
    for _, tgt in ipairs(state.targets) do
      local p = day_rec(tgt.pending, date)
      if state.focused then
        p.focused = p.focused + delta
      else
        p.unfocused = p.unfocused + delta
      end
    end
  end
  state.seg_start = now
end

-- Persist every target by merging its pending increments into the current
-- on-disk history under a lock. Pending is cleared only after a successful
-- write, so a lost lock (or a crashed peer) just defers the merge to the next
-- flush -- never a lost or double-counted increment. Safe in a libuv timer
-- callback: only uv fs, vim.json and os.time (no editor API).
local function persist()
  for _, tgt in ipairs(state.targets) do
    if not pending_empty(tgt.pending) then
      local carry
      local committed = with_lock(tgt.file, function()
        local disk = read_data(tgt.file)
        carry = merge_floored(disk, tgt.pending)
        assert(write_atomic(tgt.file, disk))
      end)
      if committed then
        tgt.pending = carry -- remainders to fold into the next flush
      end
    end
  end
end

local function flush()
  fold()
  pcall(persist)
end

local function set_focus(focused)
  fold()
  state.focused = focused
end

-- On-disk history merged with this session's still-pending increments, for
-- display only (does not mutate pending).
local function view_days(tgt)
  local days = read_data(tgt.file)
  apply_pending(days, tgt.pending)
  return days
end

local function all_time(days)
  local f, u, s = 0, 0, 0
  for _, rec in pairs(days) do
    f = f + rec.focused
    u = u + rec.unfocused
    s = s + rec.sessions
  end
  return f, u, s
end

local function fmt(sec)
  sec = math.floor(sec + 0.5)
  local h = math.floor(sec / 3600)
  local m = math.floor((sec % 3600) / 60)
  local s = sec % 60
  return string.format("%dh %02dm %02ds", h, m, s)
end

function M.open()
  if not state.enabled then
    vim.notify(
      "stats: tracking disabled here — run :StatsInit to enable it for this cwd",
      vim.log.levels.INFO
    )
    return
  end
  fold() -- include the live segment so the view is up to date

  local lines = { "", "  Neovim usage — " .. state.cwd, "" }
  for i, tgt in ipairs(state.targets) do
    if i > 1 then
      lines[#lines + 1] = ""
    end
    local days = view_days(tgt)
    local sf, su, ss = all_time(days)
    lines[#lines + 1] = "  ▌ " .. tgt.root
    lines[#lines + 1] = string.format(
      "    all time     total %s   focused %s   background %s   %d sessions",
      fmt(sf + su), fmt(sf), fmt(su), ss
    )
    local dates = vim.tbl_keys(days)
    table.sort(dates, function(a, b) return a > b end) -- most recent first
    for _, date in ipairs(dates) do
      local rec = days[date]
      lines[#lines + 1] = string.format(
        "    %s   total %s   focused %s   background %s   %d sessions",
        date, fmt(rec.focused + rec.unfocused), fmt(rec.focused), fmt(rec.unfocused), rec.sessions
      )
    end
  end
  lines[#lines + 1] = ""
  lines[#lines + 1] = "  press q to close"
  lines[#lines + 1] = ""

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].readonly = true
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "stats"
  pcall(vim.api.nvim_buf_set_name, buf, "stats://" .. state.cwd)
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, nowait = true, silent = true })

  -- Open in its own split so `q` (:close) actually closes it instead of
  -- trying (and failing) to close the last window.
  vim.cmd("botright split")
  vim.api.nvim_win_set_buf(0, buf)
  vim.api.nvim_win_set_height(0, math.min(#lines, math.max(6, vim.o.lines - 4)))
end

-- Arm the focus autocmds and the periodic flush timer (once per session).
local function arm()
  state.focused = true
  state.seg_start = uv.hrtime()

  -- Persist immediately so today's session count survives even a forceful close
  -- within the first flush interval.
  pcall(persist)

  local grp = vim.api.nvim_create_augroup("Stats", { clear = true })
  vim.api.nvim_create_autocmd("FocusGained", {
    group = grp,
    callback = function() set_focus(true) end,
  })
  vim.api.nvim_create_autocmd("FocusLost", {
    group = grp,
    callback = function() set_focus(false) end,
  })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = grp,
    callback = function()
      if state.timer then
        state.timer:stop()
        state.timer:close()
        state.timer = nil
      end
      flush()
    end,
  })

  state.timer = uv.new_timer()
  state.timer:start(state.interval, state.interval, function() flush() end)
end

-- Start tracking every discovered stats file for this session.
local function enable(found)
  if state.enabled or #found == 0 then
    return
  end
  state.enabled = true
  for _, f in ipairs(found) do
    state.targets[#state.targets + 1] = make_target(f.file, f.root)
  end
  arm()
end

-- :StatsInit — create .nvim/stats for the cwd and start tracking. If tracking is
-- already on (e.g. a parent has one), this just adds the cwd file to the set.
function M.init()
  local cwd_file = state.cwd .. "/.nvim/stats"
  vim.fn.mkdir(state.cwd .. "/.nvim", "p")
  local existed = uv.fs_stat(cwd_file) ~= nil

  if state.enabled then
    for _, tgt in ipairs(state.targets) do
      if tgt.file == cwd_file then
        vim.notify("stats: already tracking → " .. cwd_file, vim.log.levels.INFO)
        return
      end
    end
    fold() -- close out the current segment before the target set changes
    state.targets[#state.targets + 1] = make_target(cwd_file, state.cwd)
    pcall(persist)
    vim.notify("stats: also tracking → " .. cwd_file, vim.log.levels.INFO)
    return
  end

  -- create the file so discover() picks it up alongside any ancestor files
  if not existed then
    write_atomic(cwd_file, {})
  end
  enable(discover(state.cwd))
  vim.notify("stats: tracking enabled → " .. cwd_file, vim.log.levels.INFO)
end

function M.setup(opts)
  opts = opts or {}
  state.cwd = vim.fn.getcwd()
  state.interval = opts.flush_interval_ms or FLUSH_INTERVAL_MS

  -- Opt-in: only track when a .nvim/stats file exists in the cwd or a parent.
  -- Run :StatsInit to create one and start tracking; we never create it
  -- automatically. Both commands are registered even when tracking is off so
  -- :Stats can report that and :StatsInit can enable it.
  vim.api.nvim_create_user_command("Stats", M.open, {
    desc = "Show Neovim usage stats for cwd",
  })
  vim.api.nvim_create_user_command("StatsInit", M.init, {
    desc = "Create .nvim/stats and start tracking usage for cwd",
  })

  enable(discover(state.cwd))
end

return M

-- Battery notes:
--  * One libuv timer at FLUSH_INTERVAL_MS (default 60s) -- no busy loop, no
--    per-frame or per-keystroke work.
--  * Focused/background split is event-driven (FocusGained/FocusLost), which
--    only fire when you actually switch terminal tabs.
--  * Durations use a monotonic clock (uv.hrtime). On macOS that clock keeps
--    advancing during sleep, so fold() drops any segment longer than ~2x the
--    flush interval -- suspend time (and long stalls) is not counted, leaving
--    real editing time only.
