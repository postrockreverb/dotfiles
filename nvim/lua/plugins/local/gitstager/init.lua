-- gitstager: an Oil-like buffer over `git status`, in a full-screen modal.
--
-- `:Gs` covers the editor with two floats: the changed paths as a file tree on
-- the left, the diff of the row under the cursor on the right. Every verb acts
-- on that row. Dir rows carry their subtree's pathspec, so staging, unstaging,
-- discarding and previewing a dir does the whole thing below it.
--
--   <CR>    open the file (dir: fold)      s  stage
--   <C-s>   open in a vsplit               u  unstage
--   <C-h>   open in a split                x  discard, with a confirm
--   <C-t>   open in a new tab              c  commit
--   <C-w>l  into the preview (<C-w>h back) R  refresh
--   <C-d>   scroll the preview down        q  close
--   <C-u>   scroll the preview up          o  switch the previewed side
--   <C-e>   scroll the preview a line      h / l  fold / unfold
--   <C-y>   scroll it back a line          f  show only staged files
--
-- Keys and the tree width come from the lazy spec's `opts`; see config.lua.
--
-- f narrows the tree to what the next commit carries (plus conflicts), and
-- `:Gs staged` opens straight into it. It is sticky like folds, says so in the
-- tree's winbar, and turns the preview to the staged side while it lasts. u then
-- drops a row out of the view and the cursor falls onto the next one. x is off
-- there: a dir's pathspec reaches files the view hides.
--
-- The preview follows the cursor in the tree. It shows one side of the change
-- at a time, the same split the mark columns report -- unstaged (worktree
-- against index) or staged (index against HEAD) -- and o switches sides for
-- good, not just for the row under the cursor.
--
-- Opening a file closes the modal and opens it in the window `:Gs` was run
-- from. The tree buffer outlives the modal, so the next `:Gs` comes back with
-- its folds, its view and the row the cursor was on, then re-reads git status.

local config = require("plugins.local.gitstager.config")
local git = require("plugins.local.gitstager.git")
local modal = require("plugins.local.gitstager.modal")
local preview = require("plugins.local.gitstager.preview")
local tree = require("plugins.local.gitstager.tree")

local m = {}

local ns = vim.api.nvim_create_namespace("gitstager")

-- bufnr -> { root, tree, rows, folds, at, filter, files, side }
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
    -- The preview's side label. Not the mark colours: themes that leave
    -- Added/Changed to nvim's defaults get two near-identical pastels there.
    GitStagerSideStaged = "DiagnosticOk",
    GitStagerSideUnstaged = "DiagnosticWarn",
  }
  for group, link in pairs(links) do
    vim.api.nvim_set_hl(0, group, { link = link, default = true })
  end

  -- The modal paints like the editor rather than like a float: no background
  -- of its own, so a transparent Normal shows the terminal through it. The
  -- headers too -- plain text whichever side has focus, only their labels
  -- coloured.
  vim.api.nvim_set_hl(0, "GitStagerNormal", { link = "Normal", default = true })
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
    local empty = st.filter and "  nothing staged" or "  nothing to stage"
    lines = { "", st.tree and empty or "  reading git status..." }
  end

  -- Which view, and how much is in it: a filtered tree would otherwise look
  -- just like a clean worktree. Window local to the buffer, so a file opened in
  -- the window does not inherit it. No count until git has answered.
  local winbar = st.filter and "  %#GitStagerStaged#staged%*" or "  %#GitStagerDir#all%*"
  if st.tree then
    local n = st.files or 0
    winbar = winbar .. ("  %d file%s"):format(n, n == 1 and "" or "s")
  end
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    vim.wo[win][0].winbar = winbar
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

      if st.filter then
        entries = vim.tbl_filter(tree.in_staged, entries)
        st.files = #entries
        -- Nothing untracked survives the filter, so there are no `??` dirs to ask about.
        st.tree = tree.build(entries)
        return settle(buf, seq, keep, from)
      end

      local built, files = tree.build(entries), #entries
      git.untracked_dirs(st.root, tree.candidates(built), function(dirs)
        vim.schedule(function()
          if state[buf] ~= st or st.seq ~= seq then
            return
          end
          tree.apply_untracked(built, dirs)
          st.tree, st.files = built, files
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

    -- The modal steps aside and the file goes where `:Gs` was run from: the
    -- close lands focus back on that window, and the split or tab opens off it.
    modal.close()
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
  if st.filter then
    notify("discard is off in the staged view: it would reach changes the view hides", vim.log.levels.WARN)
    return false
  end

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

-- The preview follows the view onto the staged side, and goes back to the side
-- it was on when the view is left. The caller refreshes.
local function set_filter(st, on)
  if (st.filter or false) == on then
    return false
  end

  st.filter = on or nil
  if on then
    st.side = preview.side()
    preview.set_side("staged")
  else
    preview.set_side(st.side or "unstaged")
    st.side = nil
  end
  return true
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

local function close()
  modal.close()
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
  map("split", open_file("vsplit"), "Open in a vsplit")
  map("hsplit", open_file("split"), "Open in a split")
  map("tab", open_file("tabedit"), "Open in a new tab")

  map("unfold", fold(false), "Unfold")
  map("fold", fold(true), "Fold")

  map("focus_preview", modal.focus_preview, "Into the preview")
  -- Already here. Left to nvim it would walk out of the modal into the window
  -- behind, and that closes it -- as would going up or down, where the modal
  -- has nothing.
  map("focus_tree", function() end, "Stay in the tree")
  for _, lhs in ipairs({ "<C-w>j", "<C-w>k" }) do
    vim.keymap.set("n", lhs, "<Nop>", { buffer = buf, nowait = true })
    table.insert(applied, lhs)
  end

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

  map("filter", function()
    local buf = vim.api.nvim_get_current_buf()
    local st, row = current(buf)
    if st and set_filter(st, not st.filter) then
      refresh(buf, row and row.node.path or nil)
    end
  end, "Toggle showing only staged files")

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
  -- Kept alive rather than wiped: the next `:Gs` comes back to the same rows,
  -- folds and view, painted at once while git is asked again.
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

  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    buffer = buf,
    callback = function()
      state[buf] = nil
      vim.schedule(function() modal.close() end)
    end,
  })

  keymaps(buf)
end

local function create(root)
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

  if not state[buf] then
    state[buf] = { root = root, folds = {}, rows = {} }
  end

  attach(buf)
  return buf
end

-- The row the cursor was on, kept across the modal closing so the next open
-- lands on it.
local function remember(buf, win)
  local st = state[buf]
  if st and vim.api.nvim_win_is_valid(win) then
    local row = st.rows[vim.api.nvim_win_get_cursor(win)[1]]
    st.at = row and row.node.path or nil
  end
end

-- `filter`: "staged" or "all" sets the view, nil keeps whatever it was.
m.open = function(filter)
  -- Already up: `:Gs` again only brings the tree back into focus, and maybe
  -- switches the view.
  local open_tree = modal.tree()
  if open_tree then
    local buf = vim.api.nvim_win_get_buf(open_tree)
    modal.focus_tree()
    if filter and state[buf] and set_filter(state[buf], filter == "staged") then
      local _, row = current(buf)
      refresh(buf, row and row.node.path or nil)
    end
    return
  end

  local dir = vim.fn.expand("%:p:h")
  if dir == "" or vim.fn.isdirectory(dir) == 0 then
    dir = vim.fn.getcwd()
  end

  local root, err = git.root(dir)
  if not root then
    return notify(err, vim.log.levels.ERROR)
  end

  local buf = create(root)
  local st = state[buf]
  highlights()

  local tree_win, preview_win = modal.open(buf, function(win) remember(buf, win) end)
  preview.attach(preview_win, { close = close, back = modal.focus_tree })
  modal.on_resize = preview.resized

  vim.wo[tree_win][0].number = false
  vim.wo[tree_win][0].relativenumber = false
  vim.wo[tree_win][0].signcolumn = "no"
  vim.wo[tree_win][0].cursorline = true
  vim.wo[tree_win][0].wrap = false

  if filter then
    set_filter(st, filter == "staged")
  end

  -- Paint what the buffer already knows, on the row it was left on, then bring
  -- it up to date; the refresh holds that row if it is still there.
  render(buf)
  for i, row in ipairs(st.rows) do
    if row.node.path == st.at then
      vim.api.nvim_win_set_cursor(tree_win, { i, 0 })
      break
    end
  end
  refresh(buf, st.at)
end

m.setup = function(opts)
  config.setup(opts)
  highlights()
  vim.api.nvim_create_autocmd("ColorScheme", { callback = highlights })
  vim.api.nvim_create_user_command("Gs", function(args)
    local filter = args.args ~= "" and args.args or nil
    if filter and filter ~= "staged" and filter ~= "all" then
      return notify("unknown view: " .. filter .. " (staged or all)", vim.log.levels.ERROR)
    end
    m.open(filter)
  end, {
    desc = "Git stager",
    nargs = "?",
    complete = function() return { "staged", "all" } end,
  })
end

return m
