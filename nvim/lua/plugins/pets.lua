return {
  "pets",
  dir = vim.fn.stdpath("config") .. "/lua/plugins/local/pets",
  config = function()
    require("plugins.local.pets") -- init
  end,
}
