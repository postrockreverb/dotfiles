return {
  "ellisonleao/gruvbox.nvim",
  lazy = false,
  enabled = vim.g.theme == "gruvbox",
  priority = 1000,
  config = true,
  init = function()
    vim.cmd.colorscheme("gruvbox") --
  end,
}
