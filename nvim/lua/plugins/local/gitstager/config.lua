-- Defaults, overridden from the lazy spec's `opts`.
--
-- Every key is one action. Give it a string, a list of strings for several
-- bindings, or false to leave the key alone.

local m = {}

local defaults = {
  -- How much of the screen the tree keeps once a diff or a file sits beside it.
  -- Below 1 it is read as a fraction of 'columns', 1 or more as a column count.
  -- Never narrower than 20.
  tree_width = 0.25,

  keys = {
    open = "<CR>",
    split = "<C-s>",
    hsplit = "<C-h>",
    tab = "<C-t>",
    preview = "<C-p>",
    side = "o",
    scroll_down = "<C-d>",
    scroll_up = "<C-u>",
    scroll_line_down = "<C-e>",
    scroll_line_up = "<C-y>",
    fold = "h",
    unfold = "l",
    stage = "s",
    unstage = "u",
    discard = "x",
    commit = "c",
    refresh = "R",
    close = { "q", "<C-c>" },
  },
}

m.opts = vim.deepcopy(defaults)

-- Keys are replaced per action rather than deep-merged: a list value like
-- `close` would otherwise merge index by index and keep bindings you meant to
-- drop.
m.setup = function(opts)
  opts = opts or {}
  local merged = vim.deepcopy(defaults)

  if opts.tree_width then
    merged.tree_width = opts.tree_width
  end
  for action, lhs in pairs(opts.keys or {}) do
    merged.keys[action] = lhs
  end

  m.opts = merged
end

m.width = function()
  local width = m.opts.tree_width
  if width < 1 then
    width = vim.o.columns * width
  end
  return math.max(20, math.floor(width))
end

return m
