local cmd = "ConvertToTmTheme"

return {
  "convert-to-tm-theme",
  dir = vim.fn.stdpath("config") .. "/lua/plugins/local/convert-to-tm-theme",
  cmd = cmd,
  config = function()
    local tm = require("plugins.local.convert-to-tm-theme")

    local convert = function()
      local colorscheme = vim.g.colors_name or "colorscheme"
      local path = vim.fn.expand("~/.config/bat/themes/" .. colorscheme .. ".tmTheme")
      tm.convert(path)
    end

    vim.api.nvim_create_user_command(cmd, convert, { nargs = 0 })
  end,
}
