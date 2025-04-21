local cmd = "ConvertToTmTheme"

return {
  "convert-to-tm-theme",
  dir = vim.fn.stdpath("config") .. "/lua/plugins/local/convert-to-tm-theme",
  cmd = cmd,
  config = function()
    local tm = require("plugins.local.convert-to-tm-theme")
    vim.api.nvim_create_user_command(cmd, tm.convert, { nargs = 0 })
  end,
}
