local cmd_tm = "ExportTm"
local cmd_kitty = "ExportKitty"

return {
  "export-colorscheme",
  dir = vim.fn.stdpath("config") .. "/lua/plugins/local/export-colorscheme",
  cmd = {
    cmd_tm,
    cmd_kitty,
  },
  config = function()
    local export = require("plugins.local.export-colorscheme")

    local exportTm = function()
      local colorscheme = vim.g.colors_name or "colorscheme"
      local path = vim.fn.expand("~/.config/bat/themes/" .. colorscheme .. ".tmTheme")
      export.tm(path)
    end

    vim.api.nvim_create_user_command(cmd_tm, exportTm, { nargs = 0 })

    local exportKitty = function()
      local colorscheme = vim.g.colors_name or "colorscheme"
      local path = vim.fn.expand("~/.config/kitty/" .. colorscheme .. ".conf")
      export.kitty(path)
    end

    vim.api.nvim_create_user_command(cmd_kitty, exportKitty, { nargs = 0 })
  end,
}
