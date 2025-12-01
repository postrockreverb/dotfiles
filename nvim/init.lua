local themes_tbl = {
  ["rose-pine"] = true,
  ["rose-pine-dawn"] = true,
  ["zenbones"] = true,
  ["zenbones-light"] = true,
  ["flatwhite"] = true,
  ["xeno-pink"] = true,
  ["xeno-mononoke"] = true,
  ["gruvbox"] = true,
}

local theme = os.getenv("THEME")
if not themes_tbl[theme] then
  vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
  vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
  vim.cmd.colorscheme("habamax")
else
  vim.g.theme = theme
end

require("config.nvim")
require("config.lazy")
