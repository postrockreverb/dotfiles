require("config.nvim")
require("config.lazy")

-- color scheme
if os.getenv("THEME") == "habamax" then
  vim.cmd([[colorscheme habamax]])
  vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
  vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
else
  vim.cmd([[colorscheme rose-pine-main]])
end
