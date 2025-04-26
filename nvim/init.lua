local themes_tbl = {
  ["rose-pine"] = true,
  ["zenbones"] = true,
}

local theme = os.getenv("SHARED_THEME")
if not themes_tbl[theme] then
  vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
  vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
  vim.cmd.colorscheme("habamax")
else
  vim.g.shared_theme = theme
end

require("config.nvim")
require("config.lazy")
