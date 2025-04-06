return {
  "foldtext",
  dir = vim.fn.stdpath("config") .. "/lua/plugins/utils",
  event = "VeryLazy",
  config = function()
    vim.opt.foldtext = require("plugins.utils.foldtext")
  end,
}
