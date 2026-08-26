-- gitbranches: a Gs-like buffer over the repository's branches.
--
-- The buffer is the whole UI -- it takes over the current window, lists the
-- branches newest-first, and every verb acts on the row under the cursor. Two
-- views, local and remote, share the buffer; `o` switches between them.
--
--   <CR>    checkout, with a confirm       o  switch local <-> remote
--   x       delete, with a confirm         R  refresh
--   <C-p>   toggle the commits preview     S  sync: fetch --all --prune
--   <C-d>   scroll the preview down        q  close
--   <C-u>   scroll the preview up
--   <C-e>   scroll the preview a line
--   <C-y>   scroll it back a line
--
-- Rows are labelled with what matters for cleanup: [merged] when the branch
-- is contained in the default branch as origin knows it, [gone] when the
-- upstream was deleted, and the ahead/behind counts against the upstream. All
-- three are read from what is on disk, so they are as fresh as the last fetch
-- -- `S` runs one across every remote and prunes what the remotes dropped.
-- <CR> on a remote row gives you what the remote has: the local
-- tracking branch when it exists at the remote tip (created if missing),
-- detached at the remote ref when the local branch has drifted. Each view
-- marks where you are in its own terms -- the local view stars the current
-- branch, the remote view stars the remote ref HEAD sits at.
--
-- The preview is a right split that never takes focus: the cursor stays in
-- the list and moving it re-renders the preview for the row underneath. It
-- shows the branch's history from its tip.

local config = require("plugins.local.gitbranches.config")
local git = require("plugins.local.gitbranches.git")
local preview = require("plugins.local.gitbranches.preview")

local m = {}

local ns = vim.api.nvim_create_namespace("gitbranches")

-- bufnr -> { root, view, entries, all, merged, alt, seq }
local state = {}

-- Debounces the preview against cursor movement.
local timer = assert(vim.uv.new_timer())

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "gitbranches" })
end

local function highlights()
  local links = {
    GitBranchesCurrent = "Added",
    GitBranchesGone = "DiagnosticWarn",
    GitBranchesMerged = "Comment",
    GitBranchesTrack = "Changed",
    GitBranchesView = "Directory",
  }
  for group, link in pairs(links) do
    vim.api.nvim_set_hl(0, group, { link = link, default = true })
  end
end

local function render(buf)
  local st = state[buf]
  local entries = st.entries or {}

  -- Labels sit in columns -- name, ahead/behind, [gone], [merged] -- each as
  -- wide as its widest occupant. Widths come from the union of both views,
  -- so a label sits in the same column whichever view is on screen, and are
  -- display widths: the arrows are multibyte.
  local disp = vim.fn.strdisplaywidth
  local labels_of = function(entry)
    local track = (entry.ahead > 0 and ("\226\134\145" .. entry.ahead) or "")
      .. (entry.behind > 0 and ("\226\134\147" .. entry.behind) or "")
    return track, entry.gone and "[gone]" or "", st.merged[entry.name] and "[merged]" or ""
  end

  local namew, trackw, gonew, mergedw = 0, 0, 0, 0
  for _, entry in ipairs(st.all or entries) do
    local track, gone, merged = labels_of(entry)
    namew = math.max(namew, disp(entry.display))
    trackw = math.max(trackw, disp(track))
    gonew = math.max(gonew, disp(gone))
    mergedw = math.max(mergedw, disp(merged))
  end

  local rows = {}
  for _, entry in ipairs(entries) do
    local track, gone, merged = labels_of(entry)
    table.insert(rows, { entry = entry, track = track, gone = gone, merged = merged })
  end

  local lines = {}
  local marks = {}
  for i, row in ipairs(rows) do
    local entry = row.entry
    local line = (entry.current and "* " or "  ") .. entry.display
    if entry.current then
      table.insert(marks, { i - 1, 0, #line, "GitBranchesCurrent" })
    end

    if row.track ~= "" or row.gone ~= "" or row.merged ~= "" then
      line = line .. string.rep(" ", namew - disp(entry.display) + 2)
      local columns = {
        -- The counts are right-aligned so they end against the labels.
        { row.track, trackw, "GitBranchesTrack", true },
        { row.merged, mergedw, "GitBranchesMerged", false },
        { row.gone, gonew, "GitBranchesGone", false },
      }
      for _, col in ipairs(columns) do
        local text, colw, hl, right = col[1], col[2], col[3], col[4]
        if colw > 0 then
          local pad = string.rep(" ", colw - disp(text))
          if right then
            line = line .. pad
          end
          if text ~= "" then
            table.insert(marks, { i - 1, #line, #line + #text, hl })
          end
          line = line .. text .. (right and "" or pad) .. " "
        end
      end
      line = line:gsub("%s+$", "")
    end
    table.insert(lines, line)
  end

  if #lines == 0 then
    lines = { "", st.entries and "  no branches" or "  reading branches..." }
  end

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, mark in ipairs(marks) do
    vim.api.nvim_buf_set_extmark(buf, ns, mark[1], mark[2], { end_col = mark[3], hl_group = mark[4] })
  end

  -- Which view this is, painted on the list window itself.
  local win = vim.fn.bufwinid(buf)
  if win ~= -1 then
    vim.wo[win][0].winbar = ("  %%#GitBranchesView#%s%%*"):format(st.view)
  end
end

-- `keep` holds the cursor on a branch across the rows shifting underneath it.
local function settle(buf, seq, keep)
  local st = state[buf]
  if not st or st.seq ~= seq then
    return
  end

  render(buf)

  local win = vim.fn.bufwinid(buf)
  if win == -1 then
    return
  end

  local line = vim.api.nvim_win_get_cursor(win)[1]
  if keep then
    for i, entry in ipairs(st.entries) do
      if entry.name == keep then
        line = i
        break
      end
    end
  end
  vim.api.nvim_win_set_cursor(win, { math.max(1, math.min(line, vim.api.nvim_buf_line_count(buf))), 0 })

  if preview.is_open() then
    local entry = st.entries[vim.api.nvim_win_get_cursor(win)[1]]
    preview.follow(st.root, entry, true)
  end
end

-- One async snapshot per refresh, gathered entirely in git.lua. Every refresh
-- takes a sequence number, so a run overtaken by a later one drops its
-- results instead of painting them.
local function refresh(buf, keep)
  local st = state[buf]
  if not st then
    return
  end

  st.seq = (st.seq or 0) + 1
  local seq = st.seq

  git.snapshot(st.root, st.view == "remote", function(result, err)
    vim.schedule(function()
      if state[buf] ~= st or st.seq ~= seq then
        return
      end
      if not result then
        return notify(err, vim.log.levels.ERROR)
      end
      st.entries, st.all, st.merged = result.entries, result.all, result.merged
      settle(buf, seq, keep)
    end)
  end)
end

local function current(buf)
  local st = state[buf]
  if not st or not st.entries then
    return nil
  end
  return st, st.entries[vim.api.nvim_win_get_cursor(0)[1]]
end

-- Every confirm defaults to No: <CR> aborts, only an explicit `y` acts.
local function confirm(msg)
  return vim.fn.confirm(msg, "&Yes\n&No", 2) == 1
end

local function checkout()
  local buf = vim.api.nvim_get_current_buf()
  local st, entry = current(buf)
  if not st or not entry then
    return
  end

  if entry.current then
    return notify("already on " .. entry.display)
  end

  -- <CR> on a remote row means "give me what the remote has". A plain switch
  -- does that when it creates the local branch, or when the local one sits at
  -- the remote tip. A stale local branch would silently be different code, so
  -- then the remote ref is checked out detached instead -- what git itself
  -- does for `checkout origin/master`.
  local detach = false
  local what = ('branch "%s"'):format(entry.name)
  if st.view == "remote" then
    if git.local_tip_matches(st.root, entry.short, entry.name) == false then
      detach = true
      what = ('"%s", detached -- local "%s" is not at the remote tip'):format(entry.name, entry.short)
    else
      what = ('"%s" as local branch "%s"'):format(entry.name, entry.short)
    end
  end
  if not confirm("Checkout " .. what .. "?") then
    return
  end

  local res = detach and git.checkout_detach(st.root, entry.name) or git.checkout(st.root, entry.short)
  if res.code ~= 0 then
    return notify(git.err(res), vim.log.levels.ERROR)
  end
  notify(detach and ("detached at " .. entry.name) or ("on " .. entry.short))
  -- The view stays put: each one marks where you are in its own terms, so
  -- the `*` lands on the row that was just checked out.
  refresh(buf, entry.name)
end

local function delete()
  local buf = vim.api.nvim_get_current_buf()
  local st, entry = current(buf)
  if not st or not entry then
    return
  end

  if entry.detached then
    return notify("HEAD is detached -- nothing to delete", vim.log.levels.WARN)
  end
  if entry.current then
    return notify("cannot delete the checked-out branch", vim.log.levels.WARN)
  end

  if st.view == "remote" then
    if not entry.remote then
      return
    end
    if not confirm(('Delete "%s" on remote "%s"? This removes it for everyone.'):format(entry.short, entry.remote)) then
      return
    end
    -- A push is a network round trip; the list refreshes when it lands.
    notify("deleting " .. entry.name .. "...")
    git.delete_remote(st.root, entry.remote, entry.short, function(res)
      vim.schedule(function()
        if res.code ~= 0 then
          return notify(git.err(res), vim.log.levels.ERROR)
        end
        notify("deleted " .. entry.name)
        refresh(buf)
      end)
    end)
    return
  end

  if not confirm(('Delete branch "%s"?'):format(entry.name)) then
    return
  end

  local res = git.delete_local(st.root, entry.name, false)
  if res.code ~= 0 then
    -- The one thing -d refuses: commits that exist nowhere else. Losing them
    -- deserves its own question, quoting what git said.
    if not confirm(git.err(res) .. "\nForce delete?") then
      return
    end
    res = git.delete_local(st.root, entry.name, true)
    if res.code ~= 0 then
      return notify(git.err(res), vim.log.levels.ERROR)
    end
  end
  notify("deleted " .. entry.name)
  refresh(buf)
end

-- The only verb that goes to the network, so async like the remote delete: the
-- list stays usable while git works and the refresh lands when it does. One at
-- a time -- holding `S` should not stack fetches on the same repo.
local function sync()
  local buf = vim.api.nvim_get_current_buf()
  local st = state[buf]
  if not st then
    return
  end
  if st.syncing then
    return notify("already fetching")
  end

  -- Read the row now: a prune can drop it, and after a fetch the sort order
  -- moves under the cursor anyway.
  local _, entry = current(buf)
  local keep = entry and entry.name or nil

  st.syncing = true
  notify("fetching all remotes...")
  git.fetch(st.root, function(res)
    vim.schedule(function()
      if state[buf] ~= st then
        return
      end
      st.syncing = nil
      if res.code ~= 0 then
        return notify(git.err(res), vim.log.levels.ERROR)
      end
      notify("fetched")
      refresh(buf, keep)
    end)
  end)
end

local function switch_view()
  local buf = vim.api.nvim_get_current_buf()
  local st = state[buf]
  if not st then
    return
  end
  st.view = st.view == "local" and "remote" or "local"
  st.entries = nil
  render(buf)
  refresh(buf)
end

-- The preview is a satellite of the list: once the list is off screen, it
-- goes too. Except when it is the only window left -- `:q` on the list with
-- the preview open -- where closing it would be E444. Then it takes the
-- window over and shows what `q` would have left behind.
local function dismiss_preview(buf, alt)
  if #vim.fn.win_findbuf(buf) > 0 then
    return
  end

  if preview.is_open() and #vim.api.nvim_tabpage_list_wins(0) == 1 then
    local target = preview.release()
    if not target then
      return
    end
    if alt and vim.api.nvim_buf_is_valid(alt) then
      vim.api.nvim_win_set_buf(target, alt)
    else
      vim.api.nvim_win_call(target, function() vim.cmd.enew() end)
    end
    return
  end

  preview.close()
end

local function close()
  local buf = vim.api.nvim_get_current_buf()
  local st = state[buf]
  preview.close()
  if st and st.alt and vim.api.nvim_buf_is_valid(st.alt) then
    vim.api.nvim_win_set_buf(0, st.alt)
  else
    vim.cmd.enew()
  end
end

local function keymaps(buf)
  -- Reconfiguring must not leave the previous bindings behind: after a reload
  -- that rebinds or disables a key, the old one would otherwise keep answering.
  for _, lhs in ipairs(vim.b[buf].gitbranches_keys or {}) do
    pcall(vim.keymap.del, "n", lhs, { buffer = buf })
  end

  local applied = {}

  local map = function(action, rhs, desc)
    local lhs = config.opts.keys[action]
    if not lhs then
      return
    end
    local keys = type(lhs) == "table" and lhs or { lhs }
    for _, key in ipairs(keys) do
      vim.keymap.set("n", tostring(key), rhs, { buffer = buf, nowait = true, silent = true, desc = desc })
      table.insert(applied, tostring(key))
    end
  end

  map("checkout", checkout, "Checkout the branch")
  map("delete", delete, "Delete the branch")
  map("view", switch_view, "Switch between local and remote branches")

  map("preview", function()
    local st, entry = current(vim.api.nvim_get_current_buf())
    if st and entry then
      preview.toggle(st.root, entry)
    end
  end, "Toggle the commits preview")

  -- The motion fed to the preview is the scroll itself, whatever key reaches
  -- it, and falls through to the list when there is no preview to scroll.
  local scrolls = {
    scroll_down = "<C-d>",
    scroll_up = "<C-u>",
    scroll_line_down = "<C-e>",
    scroll_line_up = "<C-y>",
  }
  for action, motion in pairs(scrolls) do
    map(action, function()
      if not preview.scroll(motion) then
        vim.cmd("normal! " .. vim.keycode(motion))
      end
    end, "Scroll the preview")
  end

  map("refresh", function() refresh(vim.api.nvim_get_current_buf()) end, "Refresh")
  map("sync", sync, "Fetch every remote and prune")
  map("close", close, "Close")

  vim.b[buf].gitbranches_keys = applied
end

-- Everything here is idempotent and re-applied on every open: `:bdelete`
-- unloads the buffer and takes its buffer-local mappings with it.
local function attach(buf)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = "gitbranches"

  local group = vim.api.nvim_create_augroup("gitbranches:" .. buf, { clear = true })

  vim.api.nvim_create_autocmd("CursorMoved", {
    group = group,
    buffer = buf,
    callback = function()
      if not preview.is_open() then
        return
      end
      -- Debounced: j/k through the list should not spawn a git per row.
      timer:stop()
      timer:start(
        60,
        0,
        vim.schedule_wrap(function()
          if vim.api.nvim_get_current_buf() ~= buf then
            return
          end
          local st, entry = current(buf)
          if st then
            preview.follow(st.root, entry)
          end
        end)
      )
    end,
  })

  -- Coming back -- <C-o>, <C-^>, another window -- lands on a list built
  -- before whatever happened in between.
  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    buffer = buf,
    callback = function()
      local st = state[buf]
      if not st then
        return
      end
      if st.fresh then
        st.fresh = nil
        return
      end
      vim.schedule(function()
        if vim.api.nvim_get_current_buf() ~= buf then
          return
        end
        local _, entry = current(buf)
        refresh(buf, entry and entry.name or nil)
      end)
    end,
  })

  -- Leaving dismisses the preview, but stepping into the preview split itself
  -- must not: the test is whether the list is still on screen anywhere.
  vim.api.nvim_create_autocmd({ "BufLeave", "WinClosed" }, {
    group = group,
    buffer = buf,
    callback = function()
      local alt = state[buf] and state[buf].alt
      vim.schedule(function() dismiss_preview(buf, alt) end)
    end,
  })

  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    buffer = buf,
    callback = function()
      local alt = state[buf] and state[buf].alt
      state[buf] = nil
      vim.schedule(function() dismiss_preview(buf, alt) end)
    end,
  })

  keymaps(buf)
end

local function create(root, alt)
  local name = "gitbranches://" .. root
  local buf

  for _, other in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(other) and vim.api.nvim_buf_get_name(other) == name then
      buf = other
      break
    end
  end

  if not buf then
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buf, name)
  end

  local st = state[buf]
  if st then
    st.alt = alt or st.alt
  else
    state[buf] = { root = root, view = "local", merged = {}, alt = alt }
  end

  attach(buf)
  return buf
end

m.open = function()
  local dir = vim.fn.expand("%:p:h")
  if dir == "" or vim.fn.isdirectory(dir) == 0 then
    dir = vim.fn.getcwd()
  end

  local root, err = git.root(dir)
  if not root then
    return notify(err, vim.log.levels.ERROR)
  end

  local alt = vim.api.nvim_get_current_buf()
  local buf = create(root, state[alt] and nil or alt)
  local st = state[buf]

  highlights()
  -- Opening always lands on the local view, whatever was on screen last time.
  st.view = "local"
  -- The refresh below covers this trip, so the BufEnter it triggers should
  -- not run its own.
  st.fresh = alt ~= buf or nil
  vim.api.nvim_win_set_buf(0, buf)

  -- Buffer-scoped window options, so the window goes back to normal the
  -- moment something else lands in it.
  vim.wo[0][0].number = false
  vim.wo[0][0].relativenumber = false
  vim.wo[0][0].signcolumn = "no"
  vim.wo[0][0].cursorline = true
  vim.wo[0][0].wrap = false

  render(buf)
  refresh(buf)
end

m.setup = function(opts)
  config.setup(opts)
  highlights()
  vim.api.nvim_create_autocmd("ColorScheme", { callback = highlights })
  vim.api.nvim_create_user_command("Gb", function() m.open() end, { desc = "Git branches" })
end

return m
