local uv = vim.uv or vim.loop

local M = {}

-- How often (ms) accumulated time is persisted to .stats. A forceful close
-- (terminal tab killed without nvim shutting down gracefully) loses at most
-- this much data. A single coarse libuv timer means negligible battery impact
-- and no busy polling -- see notes at the bottom of this file.
local FLUSH_INTERVAL_MS = 60 * 1000

local state = {
  enabled = false,
  cwd = nil,
  file = nil,
  -- cumulative totals loaded from disk at startup (seconds)
  saved = { focused = 0, unfocused = 0, sessions = 0 },
  -- time accumulated during this session, already folded (seconds)
  session = { focused = 0, unfocused = 0 },
  focused = true,
  seg_start = 0, -- uv.hrtime() (ns) at the last fold
  timer = nil,
}

local function defaults()
  return { focused = 0, unfocused = 0, sessions = 0 }
end

local function read_data()
  local fd = uv.fs_open(state.file, "r", 420)
  if not fd then
    return defaults()
  end
  local stat = uv.fs_fstat(fd)
  local content = stat and uv.fs_read(fd, stat.size, 0) or ""
  uv.fs_close(fd)
  local ok, decoded = pcall(vim.json.decode, content)
  if not ok or type(decoded) ~= "table" then
    return defaults()
  end
  return {
    focused = tonumber(decoded.focused) or 0,
    unfocused = tonumber(decoded.unfocused) or 0,
    sessions = tonumber(decoded.sessions) or 0,
  }
end

-- Fold the elapsed time of the current segment into the active bucket and reset
-- the segment start. Uses a monotonic clock so it is not skewed by wall-clock
-- changes (and does not count time spent while the machine is asleep).
local function fold()
  local now = uv.hrtime()
  local delta = (now - state.seg_start) / 1e9 -- seconds
  if delta > 0 then
    if state.focused then
      state.session.focused = state.session.focused + delta
    else
      state.session.unfocused = state.session.unfocused + delta
    end
  end
  state.seg_start = now
end

local function totals()
  return {
    focused = state.saved.focused + state.session.focused,
    unfocused = state.saved.unfocused + state.session.unfocused,
    sessions = state.saved.sessions,
  }
end

-- Write current cumulative totals to .stats. Safe to call from a libuv timer
-- callback: it only touches uv fs, vim.json and os.time (no editor API).
local function persist()
  local t = totals()
  local payload = vim.json.encode({
    focused = t.focused,
    unfocused = t.unfocused,
    sessions = t.sessions,
    updated = os.time(),
  })
  local fd = uv.fs_open(state.file, "w", 420) -- 0644
  if not fd then
    return
  end
  uv.fs_write(fd, payload, 0)
  uv.fs_close(fd)
end

local function flush()
  fold()
  pcall(persist)
end

local function set_focus(focused)
  fold()
  state.focused = focused
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
  local t = totals()
  local lines = {
    "",
    "  Neovim usage — " .. state.cwd,
    "",
    "  Total open time    " .. fmt(t.focused + t.unfocused),
    "  Focused (active)   " .. fmt(t.focused),
    "  Background         " .. fmt(t.unfocused),
    "  Sessions           " .. tostring(t.sessions),
    "",
    "  This session",
    "  Focused (active)   " .. fmt(state.session.focused),
    "  Background         " .. fmt(state.session.unfocused),
    "",
    "  press q to close",
    "",
  }

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
  vim.api.nvim_win_set_height(0, #lines)
end

-- Begin tracking for this session: load totals, arm the focus autocmds and the
-- periodic flush timer. Assumes state.file already exists (persist creates it).
local function enable()
  if state.enabled then
    return
  end
  state.enabled = true

  state.saved = read_data()
  state.saved.sessions = state.saved.sessions + 1
  state.focused = true
  state.seg_start = uv.hrtime()

  -- Persist immediately so the incremented session count survives even a
  -- forceful close within the first flush interval.
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

-- :StatsInit — create .nvim/stats for the cwd and start tracking right away.
function M.init()
  if state.enabled then
    vim.notify("stats: already tracking → " .. state.file, vim.log.levels.INFO)
    return
  end
  vim.fn.mkdir(state.cwd .. "/.nvim", "p")
  enable() -- persist() inside creates the .nvim/stats file
  vim.notify("stats: tracking enabled → " .. state.file, vim.log.levels.INFO)
end

function M.setup(opts)
  opts = opts or {}
  state.cwd = vim.fn.getcwd()
  state.file = state.cwd .. "/.nvim/stats"
  state.interval = opts.flush_interval_ms or FLUSH_INTERVAL_MS

  -- Opt-in per directory: only track when a .nvim/stats file already exists.
  -- Run :StatsInit to create it and start tracking; we never create it
  -- automatically. Both commands are registered even when tracking is off so
  -- :Stats can report that and :StatsInit can enable it.
  vim.api.nvim_create_user_command("Stats", M.open, {
    desc = "Show Neovim usage stats for cwd",
  })
  vim.api.nvim_create_user_command("StatsInit", M.init, {
    desc = "Create .nvim/stats and start tracking usage for cwd",
  })

  if uv.fs_stat(state.file) ~= nil then
    enable()
  end
end

return M

-- Battery notes:
--  * One libuv timer at FLUSH_INTERVAL_MS (default 60s) -- no busy loop, no
--    per-frame or per-keystroke work.
--  * Focused/background split is event-driven (FocusGained/FocusLost), which
--    only fire when you actually switch terminal tabs.
--  * Durations use a monotonic clock, so time the laptop spends asleep is not
--    counted -- it reflects real editing time only.
