return {
  "zenbones-theme/zenbones.nvim",
  enabled = vim.g.theme == "zenbones" or vim.g.theme == "zenbones-light",
  dependencies = "rktjmp/lush.nvim",
  lazy = false,
  priority = 1000,
  init = function()
    if vim.g.theme == "zenbones-light" then
      vim.g.background = "light"
    end
    vim.g.zenbones_transparent_background = true
    vim.g.zenbones_darkness = "stark"
    vim.cmd.colorscheme("zenbones")
  end,
}
