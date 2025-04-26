return {
  "rose-pine/neovim",
  lazy = false,
  enabled = vim.g.shared_theme == "rose-pine",
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
  init = function() vim.cmd.colorscheme("rose-pine") end,
}
