return {
  "sainnhe/gruvbox-material",
  lazy = false,
  enabled = vim.g.theme == "gruvbox-material",
  priority = 1000,
  init = function()
    vim.g.gruvbox_material_better_performance = 1
    vim.cmd.colorscheme("gruvbox-material") --
  end,
}
