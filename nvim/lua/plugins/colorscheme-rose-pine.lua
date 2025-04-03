return {
  "rose-pine/neovim",
  lazy = false,
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
}
