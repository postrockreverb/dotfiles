-- The full-screen modal: the tree on the left, the preview on the right, two
-- floats over the whole editor. They come and go together -- closing either one,
-- by any route, takes the other down -- and stepping into an ordinary window
-- (a click, a tab switch) dismisses them, so the modal never lingers half seen.

local config = require("plugins.local.gitstager.config")

local m = {}

-- { tree, preview, origin, on_close } while open, nil otherwise.
local cur = nil

local group = vim.api.nvim_create_augroup("gitstager.modal", { clear = true })

local function floating(win)
  return vim.api.nvim_win_get_config(win).relative ~= ""
end

-- Borderless, whatever 'winborder' says: the two floats meet edge to edge,
-- cover everything but the command line, and read as the editor itself.
local function geometry()
  local cols = vim.o.columns
  local rows = math.max(1, vim.o.lines - vim.o.cmdheight)
  local left = math.min(config.width(), cols - 20)

  local function at(col, width)
    return {
      relative = "editor",
      row = 0,
      col = col,
      width = math.max(1, width),
      height = rows,
      border = "none",
    }
  end

  return at(0, left), at(left, cols - left)
end

m.is_open = function()
  return cur ~= nil
end

m.tree = function()
  return cur and cur.tree or nil
end

m.preview = function()
  return cur and cur.preview or nil
end

-- Where files open once the modal is gone: the window :Gs was run from.
m.origin = function()
  return cur and cur.origin or nil
end

-- Idempotent and re-entrant: the state is dropped before any window closes, so
-- the WinClosed and WinEnter those closes fire find nothing left to do. `stay`
-- leaves focus where it is, for when the user has already gone somewhere else.
m.close = function(stay)
  if not cur then
    return
  end
  local was = cur
  if was.on_close then
    pcall(was.on_close, was.tree)
  end
  cur = nil

  for _, win in ipairs({ was.preview, was.tree }) do
    if vim.api.nvim_win_is_valid(win) then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end
  if not stay and vim.api.nvim_win_is_valid(was.origin) then
    vim.api.nvim_set_current_win(was.origin)
  end
end

-- Open the floats with `tree_buf` in the left one, focused. The right one starts
-- out empty; the preview fills it. `on_close(tree_win)` runs while the tree is
-- still there to be read.
m.open = function(tree_buf, on_close)
  if cur then
    vim.api.nvim_set_current_win(cur.tree)
    return cur.tree, cur.preview
  end

  -- Run from inside some other float, files still belong in a real window.
  local origin = vim.api.nvim_get_current_win()
  if floating(origin) then
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if not floating(win) then
        origin = win
        break
      end
    end
  end

  local left, right = geometry()
  local blank = vim.api.nvim_create_buf(false, true)
  vim.bo[blank].bufhidden = "wipe"

  local preview = vim.api.nvim_open_win(blank, false, right)
  local tree = vim.api.nvim_open_win(tree_buf, true, left)
  cur = { tree = tree, preview = preview, origin = origin, on_close = on_close }

  -- Neither float takes another buffer: `:e` in the tree would bury it.
  vim.wo[tree].winfixbuf = true

  -- Window-wide, not per buffer: the preview swaps in a fresh buffer per render.
  for _, win in ipairs({ tree, preview }) do
    vim.wo[win].winhighlight = "NormalFloat:GitStagerNormal,WinBar:GitStagerNormal,WinBarNC:GitStagerNormal"
  end

  return tree, preview
end

-- Back and forth between the two, since <C-w>h/l do not walk floats.
m.focus_tree = function()
  if cur and vim.api.nvim_win_is_valid(cur.tree) then
    vim.api.nvim_set_current_win(cur.tree)
  end
end

m.focus_preview = function()
  if cur and vim.api.nvim_win_is_valid(cur.preview) then
    vim.api.nvim_set_current_win(cur.preview)
  end
end

-- `on_resize` is the preview's, so it re-renders once its float has its new size.
m.on_resize = nil

vim.api.nvim_create_autocmd("VimResized", {
  group = group,
  callback = function()
    if not cur then
      return
    end
    local left, right = geometry()
    vim.api.nvim_win_set_config(cur.tree, left)
    vim.api.nvim_win_set_config(cur.preview, right)
    if m.on_resize then
      m.on_resize()
    end
  end,
})

vim.api.nvim_create_autocmd("WinClosed", {
  group = group,
  callback = function(args)
    local closed = tonumber(args.match)
    if cur and (closed == cur.tree or closed == cur.preview) then
      vim.schedule(function() m.close() end)
    end
  end,
})

-- Other floats -- notifications, pickers, which-key -- come and go over the
-- modal freely; only an ordinary window means the user has left it.
vim.api.nvim_create_autocmd("WinEnter", {
  group = group,
  callback = function()
    if cur and not floating(vim.api.nvim_get_current_win()) then
      vim.schedule(function() m.close(true) end)
    end
  end,
})

return m
