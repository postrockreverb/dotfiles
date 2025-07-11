return {
  "rose-pine/neovim",
  lazy = false,
  enabled = vim.g.theme == "rose-pine" or vim.g.theme == "rose-pine-dawn",
  priority = 1000,
  name = "rose-pine",
  opts = {
    styles = {
      transparency = true,
    },

    highlight_groups = {
      Folded = { fg = "muted", bg = "base" },
      FoldColumn = { fg = "love", bg = "base" },
      FoldSign = { fg = "love", bg = "base" },

      IlluminatedWordRead = { underline = true, bg = "<color>" },
      IlluminatedWordText = { underline = true, bg = "<color>" },
      IlluminatedWordWrite = { underline = true, bg = "<color>" },
    },
  },
  init = function()
    local colorscheme = "rose-pine"
    if vim.g.theme == "rose-pine-dawn" then
      colorscheme = "rose-pine-dawn"
    end
    vim.cmd.colorscheme(colorscheme)
  end,
}
