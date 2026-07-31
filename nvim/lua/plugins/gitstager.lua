return {
  "gitstager",
  dir = vim.fn.stdpath("config") .. "/lua/plugins/local/gitstager",
  cmd = "Gs",
  opts = {
    -- Width the tree keeps once a diff or a file sits beside it. Under 1 it is
    -- a fraction of the screen, 1 or more a column count, never below 20.
    tree_width = 0.2,

    -- One binding per action: a string, a list of strings, or false to leave
    -- the key to nvim.
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
  },
  config = function(_, opts)
    require("plugins.local.gitstager").setup(opts) --
  end,
}
