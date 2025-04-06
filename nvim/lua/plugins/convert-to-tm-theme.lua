return {
  "convert-to-tm-theme",
  dir = vim.fn.stdpath("config") .. "/lua/plugins/utils",
  cmd = {
    "ConvertToTmTheme",
  },
  config = function()
    require("plugins.utils.convert-to-tm-theme")
  end,
}
