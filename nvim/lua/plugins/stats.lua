return {
  "stats",
  dir = vim.fn.stdpath("config") .. "/lua/plugins/local/stats",
  lazy = false, -- load at startup so tracking begins immediately
  config = function()
    require("plugins.local.stats").setup()
  end,
}
