return {
  "foldtext",
  dir = vim.fn.stdpath("config") .. "/lua/plugins/local/foldtext",
  event = "VeryLazy",
  config = function() vim.opt.foldtext = require("plugins.local.foldtext") end,
}
