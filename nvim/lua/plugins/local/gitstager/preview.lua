-- Read-only diff preview: delta for anything with an index side, bat for
-- untracked files. Rendered into a terminal buffer so the ANSI colours those
-- two produce survive, in a right split that never takes focus -- the tree
-- keeps the cursor and drives what is shown.

local config = require("plugins.local.gitstager.config")
local git = require("plugins.local.gitstager.git")
local tree = require("plugins.local.gitstager.tree")

local m = {}

-- The split is a singleton: previewing another row reuses it rather than
-- stacking splits.
local win = -1
local shown = nil
local last = nil
local rendered_width = nil
local resize_timer = assert(vim.uv.new_timer())
-- Which side of the change is on screen: "unstaged" (worktree against the
-- index, the Y column) or "staged" (index against HEAD, the X column). Sticky
-- until switched, so reviewing a run of files stays on one side.
local side = "unstaged"
-- Bumped per render so results that arrive after a newer one are dropped.
local token = 0

-- Caps on the synthesized untracked patch: files, and lines across them.
local MAX_NEW_FILES = 50
local MAX_NEW_LINES = 2000

-- Resolved once, on the main loop: everything downstream of a vim.system
-- callback runs in a libuv context where vim.fn is off limits.
local HAS = {
  bat = vim.fn.executable("bat") == 1,
  delta = vim.fn.executable("delta") == 1,
}

-- Reads through vim.uv rather than vim.fn.readfile, for the same reason.
local function read_lines(path, max)
  local fd = vim.uv.fs_open(path, "r", 438)
  if not fd then
    return nil
  end

  local stat = vim.uv.fs_fstat(fd)
  local data = stat and vim.uv.fs_read(fd, math.min(stat.size, 1024 * 1024), 0) or nil
  vim.uv.fs_close(fd)
  if not data then
    return nil
  end

  local binary = data:find("\0", 1, true) ~= nil
  local lines = vim.split(data, "\n", { plain = true })
  if lines[#lines] == "" then
    table.remove(lines)
  end
  if max and #lines > max then
    lines = vim.list_slice(lines, 1, max)
  end
  return lines, binary
end

local function read_plain(file)
  local lines = read_lines(file, MAX_NEW_LINES)
  return lines and table.concat(lines, "\n") or ""
end

local function exists()
  return vim.api.nvim_win_is_valid(win)
end

-- There is one preview split, and it belongs to the tab you are looking at.
-- Rendering from another tab must not paint into a window nobody can see.
local function alive()
  return exists() and vim.api.nvim_win_get_tabpage(win) == vim.api.nvim_get_current_tabpage()
end

m.is_open = alive

local function width()
  if alive() then
    return vim.api.nvim_win_get_width(win)
  end
  return math.max(20, vim.o.columns - config.width() - 1)
end

local function bat(root, path, cols, on_done)
  local args = { "bat", "--color=always", "--style=numbers", "--tabs=2", "--paging=never" }
  table.insert(args, "--terminal-width=" .. cols)
  if vim.g.theme then
    table.insert(args, "--theme=" .. vim.g.theme)
  end
  vim.list_extend(args, { "--", path })

  vim.system(args, { cwd = root, text = true }, function(res)
    on_done(res.code == 0 and res.stdout or nil)
  end)
end

local function delta(text, cols, on_done)
  -- --color-only keeps the patch structurally intact, and delta then prepends
  -- its line numbers. Emptying the left format collapses its usual two columns
  -- into one: the line number in the new file, blank on deleted lines.
  local args = {
    "delta",
    "--color-only",
    "--paging=never",
    "--line-numbers",
    "--line-numbers-left-format=",
    "--line-numbers-right-format={np:>4} ",
    "--width=" .. cols,
  }
  vim.system(args, { stdin = text, text = true }, function(res)
    on_done(res.code == 0 and res.stdout or nil)
  end)
end

-- A dir row can sit over thousands of untracked files. One `git diff --no-index`
-- each meant 29 seconds for 2,000 of them, so the "new file" patch is written
-- here instead -- no processes -- and capped, since delta is no faster than we
-- are at chewing through a 30MB diff.
local function new_file_patch(root, paths)
  local out = {}
  local lines_left = MAX_NEW_LINES
  local files = 0

  for _, path in ipairs(paths) do
    if files >= MAX_NEW_FILES or lines_left <= 0 then
      break
    end

    local lines, binary = read_lines(root .. "/" .. path, lines_left)
    if lines then
      files = files + 1
      table.insert(out, ("diff --git a/%s b/%s"):format(path, path))
      table.insert(out, "new file mode 100644")
      table.insert(out, "--- /dev/null")
      table.insert(out, "+++ b/" .. path)

      if binary then
        table.insert(out, "Binary file differs")
      else
        table.insert(out, ("@@ -0,0 +1,%d @@"):format(#lines))
        for _, line in ipairs(lines) do
          table.insert(out, "+" .. line)
        end
        lines_left = lines_left - #lines
      end
    end
  end

  local skipped = #paths - files
  if skipped > 0 then
    table.insert(out, ("... and %d more untracked file%s"):format(skipped, skipped == 1 and "" or "s"))
  end

  return #out > 0 and (table.concat(out, "\n") .. "\n") or ""
end

-- The worktree side also carries what is not in the index at all: untracked
-- files, as whole-file additions, so a dir row previews everything it would
-- stage. The index side has none of them by definition.
local function patch(root, node, on_done)
  git.diff(root, node.path, side == "staged", function(text)
    if side == "staged" then
      return on_done(text)
    end
    on_done(text .. new_file_patch(root, tree.untracked_files(node)))
  end)
end

m.close = function()
  if exists() then
    vim.api.nvim_win_close(win, true)
  end
  win, shown, last = -1, nil, nil
end

-- Hand the split over to a real file: the window stays, the preview lets go of
-- it. The locks it kept on itself have to come off, or nothing else can be put
-- there or resized. Returns the window, or nil if there was no preview.
m.takeover = function()
  if not alive() then
    return nil
  end

  local target = win
  vim.wo[target].winfixbuf = false
  vim.wo[target].winfixwidth = false
  win, shown, last = -1, nil, nil
  return target
end

-- Put `buf` in the preview split, creating it if needed, and hand focus back to
-- wherever it was -- <C-p> and cursor movement both stay in the tree.
local function place(buf)
  local from = vim.api.nvim_get_current_win()

  if alive() then
    -- Swapping the buffer is what 'winfixbuf' guards against.
    vim.wo[win].winfixbuf = false
    vim.api.nvim_win_set_buf(win, buf)
  else
    -- A preview left behind in another tab: take it down first, one at a time.
    if exists() then
      vim.api.nvim_win_close(win, true)
    end
    vim.cmd("botright vsplit")
    win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, buf)
    if vim.api.nvim_win_is_valid(from) then
      vim.api.nvim_win_set_width(from, config.width())
      vim.wo[from][0].winfixwidth = true
    end
  end

  vim.wo[win][0].number = false
  vim.wo[win][0].relativenumber = false
  vim.wo[win][0].signcolumn = "no"
  vim.wo[win][0].wrap = false
  vim.wo[win].winfixwidth = true
  vim.wo[win].winfixbuf = true

  if vim.api.nvim_win_is_valid(from) then
    vim.api.nvim_set_current_win(from)
  end
end

local function top()
  if alive() then
    vim.api.nvim_win_call(win, function() vim.cmd("normal! gg") end)
  end
end

local function show(text, colored)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"

  -- Place first: nvim_open_term sizes the terminal grid to the window showing
  -- the buffer, and opening it while the narrow tree was current would paint
  -- the diff into a tree-wide sliver of the preview.
  place(buf)
  rendered_width = vim.api.nvim_win_get_width(win)
  -- Which side, and of what: the diff headers name the file, but an empty side
  -- or a bat-rendered untracked file would otherwise say neither.
  vim.wo[win][0].winbar = ("  %%#GitStagerDir#%s%%*  %s"):format(side, shown or "")

  if colored then
    vim.api.nvim_win_call(win, function()
      local chan = vim.api.nvim_open_term(buf, {})
      vim.api.nvim_chan_send(chan, (text:gsub("\n", "\r\n")))
    end)
  else
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(text, "\n", { plain = true }))
    vim.bo[buf].filetype = "diff"
  end

  vim.bo[buf].modifiable = false

  for _, lhs in ipairs({ "q", "<Esc>", "<C-p>", "<C-c>" }) do
    vim.keymap.set("n", lhs, m.close, { buffer = buf, nowait = true, desc = "Close preview" })
  end
  -- A terminal buffer would otherwise drop into terminal mode.
  for _, lhs in ipairs({ "i", "I", "a", "A", "o", "O" }) do
    vim.keymap.set("n", lhs, "<Nop>", { buffer = buf, nowait = true })
  end

  -- The terminal renders asynchronously, so reset the view once it has.
  vim.schedule(top)
  vim.defer_fn(top, 40)
end

-- Render `node`. Without `force`, re-rendering the row already on screen is a
-- no-op, which is what keeps cursor-following cheap.
local function render(root, node, force)
  if not force and shown == node.path then
    return
  end
  shown, last = node.path, { root = root, node = node }

  local cols = width()
  -- Cursor movement can outrun git and delta; only the newest render paints.
  token = token + 1
  local mine = token

  local function paint(text, colored)
    vim.schedule(function()
      -- `shown` going nil means the split was closed while git was working.
      if mine ~= token or shown == nil then
        return
      end
      show(text or "", colored)
    end)
  end

  -- Half the rows have nothing on one side -- an `A ` file has no worktree
  -- side, a `??` file no index side -- so say which side is empty, rather than
  -- leaving a blank pane to be read as a bug.
  local function nothing()
    paint(("nothing %s %s %s"):format(side, node.is_dir and "under" or "in", node.path), false)
  end

  -- An untracked file exists only in the worktree, and has no index side.
  if node.untracked and not node.is_dir then
    if side == "staged" then
      return nothing()
    end
    if HAS.bat then
      return bat(root, node.path, cols, function(out)
        if out then
          return paint(out, true)
        end
        paint(read_plain(root .. "/" .. node.path), false)
      end)
    end
    return paint(read_plain(root .. "/" .. node.path), false)
  end

  patch(root, node, function(text)
    if vim.trim(text) == "" then
      return nothing()
    end
    if not HAS.delta then
      return paint(text, false)
    end
    delta(text, cols, function(out) paint(out or text, out ~= nil) end)
  end)
end

-- Switch sides and show it, opening the split if it was closed -- a mode you
-- cannot see is worse than no mode.
m.flip = function(root, node)
  side = side == "unstaged" and "staged" or "unstaged"
  render(root, node, true)
end

-- <C-p>: open on this row, or close if it is already the one on screen.
m.toggle = function(root, node)
  if alive() and shown == node.path then
    return m.close()
  end
  render(root, node, true)
end

-- Cursor moved in the tree, or the tree changed under it.
m.follow = function(root, node, force)
  if not alive() then
    return
  end
  if not node then
    return m.close()
  end
  render(root, node, force)
end

-- A terminal grid keeps the width it was born with, and delta was told that
-- width too, so any resize means rendering the diff again. Debounced, because
-- dragging a window border emits a resize per column.
local function resize()
  if not alive() or not last or vim.api.nvim_win_get_width(win) == rendered_width then
    return
  end

  resize_timer:stop()
  resize_timer:start(
    80,
    0,
    vim.schedule_wrap(function()
      if alive() and last then
        render(last.root, last.node, true)
      end
    end)
  )
end

vim.api.nvim_create_autocmd({ "WinResized", "VimResized" }, { callback = resize })

m.scroll = function(key)
  if not alive() then
    return false
  end
  vim.api.nvim_win_call(win, function() vim.cmd("normal! " .. vim.keycode(key)) end)
  return true
end

return m
