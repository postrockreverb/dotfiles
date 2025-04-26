return {
  "zenbones-theme/zenbones.nvim",
  enabled = vim.g.shared_theme == "zenbones",
  dependencies = "rktjmp/lush.nvim",
  lazy = false,
  priority = 1000,
  init = function()
    vim.g.zenbones_transparent_background = true
    vim.g.zenbones_darkness = "stark"
    vim.cmd.colorscheme("zenbones")
  end,
}
