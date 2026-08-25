-- gitstager: an Oil-like buffer over `git status`.
--
-- The buffer is the whole UI -- it takes over the current window, lists the
-- changed paths as a file tree, and every verb acts on the row under the
-- cursor. Dir rows carry their subtree's pathspec, so staging, unstaging,
-- discarding and previewing a dir does the whole thing below it.
--
--   <CR>    open the file (dir: fold)      s  stage
--   <C-s>   open right, over the preview   u  unstage
--   <C-h>   open in a split                x  discard, with a confirm
--   <C-t>   open in a new tab              c  commit
--   <C-p>   toggle the diff preview        R  refresh
--   <C-d>   scroll the preview down        q  close
--   <C-u>   scroll the preview up          o  switch the previewed side
--   <C-e>   scroll the preview a line      h / l  fold / unfold
--   <C-y>   scroll it back a line
--
-- Keys and the tree width come from the lazy spec's `opts`; see config.lua.
--
-- The preview is a right split that never takes focus: the cursor stays in the
-- tree and moving it re-renders the preview for the row underneath. It shows
-- one side of the change at a time, the same split the mark columns report --
-- unstaged (worktree against index) or staged (index against HEAD) -- and o
-- switches sides for good, not just for the row under the cursor.
--
-- The tree buffer outlives <CR>, so <C-o> from the file jumps back onto the row
-- it was opened from and <C-i> jumps forward again -- plain nvim jumps, no
-- mapping. Returning re-reads git status; folds survive.

local config = require("plugins.local.gitstager.config")
local git = require("plugins.local.gitstager.git")
local preview = require("plugins.local.gitstager.preview")
local tree = require("plugins.local.gitstager.tree")

local m = {}

local ns = vim.api.nvim_create_namespace("gitstager")

-- bufnr -> { root, tree, rows, folds, alt }
local state = {}

-- Debounces the preview against cursor movement.
local timer = assert(vim.uv.new_timer())

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "gitstager" })
end

local function highlights()
  local links = {
    GitStagerStaged = "Added",
    GitStagerDirty = "Changed",
    GitStagerUntracked = "Comment",
    GitStagerConflict = "DiagnosticError",
    GitStagerDir = "Directory",
  }
  for group, link in pairs(links) do
    vim.api.nvim_set_hl(0, group, { link = link, default = true })
  end
end

-- Both columns share the grammar, so only the "changed" letter differs: the
-- staged column reads as added, the worktree column as modified.
local function mark_hl(char, staged_column)
  if char == " " then
    return nil
  elseif char == "?" then
    return "GitStagerUntracked"
  elseif char == "U" then
    return "GitStagerConflict"
  end
  return staged_column and "GitStagerStaged" or "GitStagerDirty"
end

local function render(buf)
  local st = state[buf]
  st.rows = st.tree and tree.rows(st.tree, st.folds) or {}

  local lines = {}
  for _, row in ipairs(st.rows) do
    local indent = string.rep("  ", row.depth)
    table.insert(lines, row.node.x .. row.node.y .. "  " .. indent .. row.display)
  end
  if #lines == 0 then
    -- Nothing to paint yet on the very first open; git is on its way.
    lines = { "", st.tree and "  nothing to stage" or "  reading git status..." }
  end

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for i, row in ipairs(st.rows) do
    local line = i - 1
    local x = mark_hl(row.node.x, true)
    local y = mark_hl(row.node.y, false)
    if x then
      vim.api.nvim_buf_set_extmark(buf, ns, line, 0, { end_col = 1, hl_group = x })
    end
    if y then
      vim.api.nvim_buf_set_extmark(buf, ns, line, 1, { end_col = 2, hl_group = y })
    end
    if row.is_dir then
      local col = 4 + row.depth * 2
      vim.api.nvim_buf_set_extmark(buf, ns, line, col, { end_col = #lines[i], hl_group = "GitStagerDir" })
    end
  end
end

-- `from` is where the cursor sat when the refresh was fired. Holding a row
-- across shifting rows is the point of `keep`, but the refresh lands ~150ms
-- later, and by then the cursor may have moved on -- that is the user's, not
-- ours to overrule.
local function settle(buf, seq, keep, from)
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
  if keep and (from == nil or from == line) then
    for i, row in ipairs(st.rows) do
      if row.node.path == keep then
        line = i
        break
      end
    end
  end

  vim.api.nvim_win_set_cursor(win, { math.max(1, math.min(line, vim.api.nvim_buf_line_count(buf))), 0 })

  if preview.is_open() then
    local row = st.rows[vim.api.nvim_win_get_cursor(win)[1]]
    preview.follow(st.root, row and row.node or nil, true)
  end
end

-- Two git calls, both off the main loop: status for the rows, then ls-files to
-- settle which dirs are `??`. Every refresh takes a sequence number, so a run
-- overtaken by a later one drops its results instead of painting them.
local function refresh(buf, keep)
  local st = state[buf]
  if not st then
    return
  end

  st.seq = (st.seq or 0) + 1
  local seq = st.seq

  local win = vim.fn.bufwinid(buf)
  local from = win ~= -1 and vim.api.nvim_win_get_cursor(win)[1] or nil

  git.status(st.root, function(entries, err)
    vim.schedule(function()
      -- state[buf] ~= st means the buffer was wiped and rebuilt underneath us.
      if state[buf] ~= st or st.seq ~= seq then
        return
      end
      if not entries then
        return notify(err, vim.log.levels.ERROR)
      end

      local built = tree.build(entries)
      git.untracked_dirs(st.root, tree.candidates(built), function(dirs)
        vim.schedule(function()
          if state[buf] ~= st or st.seq ~= seq then
            return
          end
          tree.apply_untracked(built, dirs)
          st.tree = built
          settle(buf, seq, keep, from)
        end)
      end)
    end)
  end)
end

local function current(buf)
  local st = state[buf]
  if not st then
    return nil
  end
  return st, st.rows[vim.api.nvim_win_get_cursor(0)[1]]
end

-- Wrap a verb so it always gets the row under the cursor, and refreshes onto
-- the same path afterwards.
local function verb(fn)
  return function()
    local buf = vim.api.nvim_get_current_buf()
    local st, row = current(buf)
    if not st or not row then
      return
    end
    if fn(st, row) ~= false then
      refresh(buf, row.node.path)
    end
  end
end

local function check(res)
  if res.code ~= 0 then
    notify(git.err(res), vim.log.levels.ERROR)
    return false
  end
  return true
end

local function open_file(cmd)
  return function()
    local buf = vim.api.nvim_get_current_buf()
    local st, row = current(buf)
    if not st or not row then
      return
    end

    if row.is_dir then
      st.folds[row.node.path] = not st.folds[row.node.path] or nil
      return render(buf)
    end

    local path = st.root .. "/" .. row.node.path
    if vim.fn.filereadable(path) == 0 then
      return notify(row.node.path .. " does not exist on disk", vim.log.levels.WARN)
    end

    -- <C-s> lands where the diff was: the preview is already the window you
    -- were reading, and splitting again would make a third one.
    if cmd == "vsplit" then
      local target = preview.takeover()
      if target then
        vim.api.nvim_set_current_win(target)
        return vim.cmd.edit(vim.fn.fnameescape(path))
      end

      -- With no preview to inherit, build the same shape: the tree keeps its
      -- slice, the file takes the rest. Width is set once here and never
      -- locked; afterwards vim's normal resizing rules apply.
      local tree_win = vim.api.nvim_get_current_win()
      vim.cmd(("vsplit %s"):format(vim.fn.fnameescape(path)))
      if vim.api.nvim_win_is_valid(tree_win) then
        vim.api.nvim_win_set_width(tree_win, config.width())
      end
      return
    end

    vim.cmd[cmd](vim.fn.fnameescape(path))
  end
end

local function fold(closed)
  return function()
    local buf = vim.api.nvim_get_current_buf()
    local st, row = current(buf)
    if not st or not row or not row.is_dir then
      return
    end
    st.folds[row.node.path] = closed or nil
    render(buf)
  end
end

-- The one verb that destroys work, so it never trusts the painted rows: ask git
-- what is actually there right now, and say how much of it is going.
local function discard(st, row)
  local path = row.node.path
  local n = git.changes_under(st.root, path)
  if n == 0 then
    notify("nothing to discard in " .. path)
    return
  end

  local what = row.is_dir and ("%s/ (%d changed files)"):format(path, n) or path
  if vim.fn.confirm("Discard all changes in " .. what .. "?", "&Yes\n&No", 2) ~= 1 then
    return false
  end
  check(git.discard(st.root, path, row.node.tracked, row.node.untracked))
end

local function commit()
  local buf = vim.api.nvim_get_current_buf()
  local st = state[buf]
  if not st then
    return
  end

  if not git.has_staged(st.root) then
    return notify("nothing staged", vim.log.levels.WARN)
  end

  local message = vim.fn.input("Commit message: ")
  vim.cmd("redraw")
  if vim.trim(message) == "" then
    return notify("commit aborted")
  end

  local res = git.commit(st.root, message)
  if check(res) then
    notify(vim.split(vim.trim(res.stdout or ""), "\n")[1] or "committed")
  end
  refresh(buf)
end

-- The preview is a satellite of the tree: once the tree is off screen, it goes
-- too. Except when it is the only window left -- `:q` on the tree with the
-- preview open -- where closing it would be E444. Then it takes the window over
-- and shows what `q` would have left behind.
local function dismiss_preview(buf, alt)
  if #vim.fn.win_findbuf(buf) > 0 then
    return
  end

  if preview.is_open() and #vim.api.nvim_tabpage_list_wins(0) == 1 then
    local target = preview.takeover()
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
  for _, lhs in ipairs(vim.b[buf].gitstager_keys or {}) do
    pcall(vim.keymap.del, "n", lhs, { buffer = buf })
  end

  local applied = {}

  -- One action, whatever it is bound to: a string, a list of them, or false to
  -- leave the key to nvim.
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

  map("open", open_file("edit"), "Open")
  map("split", open_file("vsplit"), "Open beside the tree, over the preview")
  map("hsplit", open_file("split"), "Open in a split")
  map("tab", open_file("tabedit"), "Open in a new tab")

  map("unfold", fold(false), "Unfold")
  map("fold", fold(true), "Fold")

  map("preview", function()
    local st, row = current(vim.api.nvim_get_current_buf())
    if st and row then
      preview.toggle(st.root, row.node)
    end
  end, "Toggle diff preview")

  map("side", function()
    local st, row = current(vim.api.nvim_get_current_buf())
    if st and row then
      preview.flip(st.root, row.node)
    end
  end, "Switch the preview between the staged and unstaged side")

  -- The motion fed to the preview is the scroll itself, whatever key reaches
  -- it, and falls through to the tree when there is no preview to scroll.
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

  map("stage", verb(function(st, row) check(git.stage(st.root, row.node.path)) end), "Stage")
  map("unstage", verb(function(st, row) check(git.unstage(st.root, row.node.path)) end), "Unstage")
  map("discard", verb(discard), "Discard")
  map("commit", commit, "Commit")
  map("refresh", function() refresh(vim.api.nvim_get_current_buf()) end, "Refresh")
  map("close", close, "Close")

  vim.b[buf].gitstager_keys = applied
end

-- Everything here is idempotent and re-applied on every open: `:bdelete` unloads
-- the buffer and takes its buffer-local mappings with it, leaving a tree that
-- looks right and answers to nothing.
local function attach(buf)
  vim.bo[buf].buftype = "nofile"
  -- Kept alive rather than wiped: the jump list entry <CR> pushes stays valid,
  -- so <C-o> back into the tree and <C-i> forward into the file are nvim's own
  -- jumps, landing on the row the file was opened from.
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = "gitstager"

  local group = vim.api.nvim_create_augroup("gitstager:" .. buf, { clear = true })

  vim.api.nvim_create_autocmd("CursorMoved", {
    group = group,
    buffer = buf,
    callback = function()
      if not preview.is_open() then
        return
      end
      -- Debounced: j/k through a big tree should not spawn a git and a delta
      -- per row.
      timer:stop()
      timer:start(
        60,
        0,
        vim.schedule_wrap(function()
          if vim.api.nvim_get_current_buf() ~= buf then
            return
          end
          local st, row = current(buf)
          if st then
            preview.follow(st.root, row and row.node or nil)
          end
        end)
      )
    end,
  })

  -- Coming back -- <C-o>, <C-^>, another window -- lands on a tree that was
  -- built before the file was edited.
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
      -- Scheduled: a jump back positions the cursor after BufEnter, and the
      -- row it lands on is the one to hold on to.
      vim.schedule(function()
        if vim.api.nvim_get_current_buf() ~= buf then
          return
        end
        local row = st.rows[vim.api.nvim_win_get_cursor(0)[1]]
        refresh(buf, row and row.node.path or nil)
      end)
    end,
  })

  -- Leaving for a file dismisses the preview, but stepping into the preview
  -- split itself must not: the test is whether the tree is still on screen
  -- anywhere. `:q`, `<C-w>q` and `:close` all arrive here too.
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
  local name = "gitstager://" .. root
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
    state[buf] = { root = root, folds = {}, rows = {}, alt = alt }
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

  highlights()
  -- The refresh below covers this trip, so the BufEnter it triggers should not
  -- run its own -- but only if there is one: `:Gs` from inside the tree changes
  -- no buffer, and a flag left standing would swallow the next real return.
  state[buf].fresh = alt ~= buf or nil
  vim.api.nvim_win_set_buf(0, buf)

  -- Buffer-scoped window options, so the window goes back to normal the moment
  -- <CR> puts a file in it.
  vim.wo[0][0].number = false
  vim.wo[0][0].relativenumber = false
  vim.wo[0][0].signcolumn = "no"
  vim.wo[0][0].cursorline = true
  vim.wo[0][0].wrap = false

  -- Paint what the buffer already knows -- the tree survives <CR>, so reopening
  -- shows the previous rows at once -- then bring it up to date.
  render(buf)
  refresh(buf)
end

m.setup = function(opts)
  config.setup(opts)
  highlights()
  vim.api.nvim_create_autocmd("ColorScheme", { callback = highlights })
  vim.api.nvim_create_user_command("Gs", function() m.open() end, { desc = "Git stager" })
end

return m
