require("config.nvim")
require("config.lazy")

-- color scheme
if os.getenv("theme") == "habamax" then
  vim.cmd([[colorscheme habamax]])
else
  vim.cmd([[colorscheme rose-pine-main]])
end

if os.getenv("bg") == "transparent" then
  vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
end
