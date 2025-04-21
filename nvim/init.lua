local themes_tbl = {
  ["rose-pine"] = true,
  ["zenbones"] = true,
}

local theme = os.getenv("SHARED_THEME")
if not themes_tbl[theme] then
  theme = "habamax"
  vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
  vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
end
vim.g.shared_theme = theme

require("config.nvim")
require("config.lazy")

vim.cmd([[colorscheme ]] .. theme)
