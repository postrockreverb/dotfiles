-- Read-only commits preview: `git log --graph` rendered into a terminal
-- buffer so its colours survive, in a right split that never takes focus --
-- the list keeps the cursor and drives what is shown.

local config = require("plugins.local.gitbranches.config")
local git = require("plugins.local.gitbranches.git")

local m = {}

-- The split is a singleton: previewing another branch reuses it rather than
-- stacking splits.
local win = -1
local shown = nil
-- Bumped per render so results that arrive after a newer one are dropped.
local token = 0

local function exists()
  return vim.api.nvim_win_is_valid(win)
end

-- There is one preview split, and it belongs to the tab you are looking at.
-- Rendering from another tab must not paint into a window nobody can see.
local function alive()
  return exists() and vim.api.nvim_win_get_tabpage(win) == vim.api.nvim_get_current_tabpage()
end

m.is_open = alive

m.close = function()
  if exists() then
    vim.api.nvim_win_close(win, true)
  end
  win, shown = -1, nil
end

-- Give the window up without closing it, for the one case where closing is
-- E444: the list going away while the preview is the only other window.
-- 'winfixbuf' has to come off or nothing else can be put there.
m.release = function()
  if not alive() then
    return nil
  end
  local target = win
  vim.wo[target].winfixbuf = false
  win, shown = -1, nil
  return target
end

-- Put `buf` in the preview split, creating it if needed, and hand focus back
-- to wherever it was -- <C-p> and cursor movement both stay in the list.
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
    -- The list keeps its slice, the preview takes the rest. Width is set once
    -- here and never locked; afterwards vim's normal resizing rules apply.
    if vim.api.nvim_win_is_valid(from) then
      vim.api.nvim_win_set_width(from, config.width())
    end
  end

  vim.wo[win][0].number = false
  vim.wo[win][0].relativenumber = false
  vim.wo[win][0].signcolumn = "no"
  vim.wo[win][0].wrap = false
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

local function show(text)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"

  -- Place first: nvim_open_term sizes the terminal grid to the window showing
  -- the buffer, and opening it while the narrow list was current would paint
  -- the log into a list-wide sliver of the preview.
  place(buf)
  vim.wo[win][0].winbar = ("  %%#GitBranchesView#%s%%*"):format(shown or "")

  vim.api.nvim_win_call(win, function()
    local chan = vim.api.nvim_open_term(buf, {})
    vim.api.nvim_chan_send(chan, (text:gsub("\n", "\r\n")))
  end)
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

-- Render `entry`. Without `force`, re-rendering the branch already on screen
-- is a no-op, which is what keeps cursor-following cheap.
local function render(root, entry, force)
  if not force and shown == entry.name then
    return
  end
  shown = entry.name

  -- Cursor movement can outrun git; only the newest render paints.
  token = token + 1
  local mine = token

  git.log(root, entry.name, function(text)
    vim.schedule(function()
      -- `shown` going nil means the split was closed while git was working.
      if mine ~= token or shown == nil then
        return
      end
      if vim.trim(text) == "" then
        text = "no commits on " .. entry.name
      end
      show(text)
    end)
  end)
end

-- <C-p>: open on this row, or close if it is already the one on screen.
m.toggle = function(root, entry)
  if alive() and shown == entry.name then
    return m.close()
  end
  render(root, entry, true)
end

-- Cursor moved in the list, or the list changed under it.
m.follow = function(root, entry, force)
  if not alive() then
    return
  end
  if not entry then
    return m.close()
  end
  render(root, entry, force)
end

m.scroll = function(key)
  if not alive() then
    return false
  end
  vim.api.nvim_win_call(win, function() vim.cmd("normal! " .. vim.keycode(key)) end)
  return true
end

return m
