return {
  "gitbranches",
  dir = vim.fn.stdpath("config") .. "/lua/plugins/local/gitbranches",
  cmd = "Gb",
  opts = {
    -- Width the list keeps once the commits preview sits beside it. Under 1
    -- it is a fraction of the screen, 1 or more a column count, never below 20.
    list_width = 0.2,

    -- One binding per action: a string, a list of strings, or false to leave
    -- the key to nvim.
    keys = {
      checkout = "<CR>",
      delete = "x",
      view = "o",
      preview = "<C-p>",
      scroll_down = "<C-d>",
      scroll_up = "<C-u>",
      scroll_line_down = "<C-e>",
      scroll_line_up = "<C-y>",
      refresh = "R",
      sync = "S",
      close = { "q", "<C-c>" },
    },
  },
  config = function(_, opts)
    require("plugins.local.gitbranches").setup(opts) --
  end,
}
