return {
  "postrockreverb/flatwhite.nvim",
  lazy = false,
  enabled = vim.g.theme == "flatwhite",
  priority = 1000,
  config = true,
  init = function()
    vim.cmd.colorscheme("flatwhite") --
  end,
}
