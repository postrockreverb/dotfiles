return {
  "rose-pine/neovim",
  lazy = false,
  priority = 1000,
  name = "rose-pine",
  opts = {
    styles = {
      transparency = true,
    },

    groups = {
      border = "muted",
      link = "iris",
      panel = "surface",

      error = "love",
      hint = "iris",
      info = "foam",
      note = "pine",
      todo = "rose",
      warn = "gold",

      git_add = "foam",
      git_change = "gold",
      git_delete = "love",
      git_dirty = "gold",
      git_ignore = "muted",
      git_merge = "iris",
      git_rename = "pine",
      git_stage = "iris",
      git_text = "gold",
      git_untracked = "love",

      h1 = "iris",
      h2 = "foam",
      h3 = "rose",
      h4 = "gold",
      h5 = "pine",
      h6 = "foam",
    },

    highlight_groups = {
      Number = { fg = "#5BC1A2" },
      LineNr4 = { fg = "#3B4261" },
      LineNr3 = { fg = "#445464" },
      LineNr2 = { fg = "#5D8E97" },
      LineNr1 = { fg = "#7DAEB9" },
      LineNr0 = { fg = "#bDeEf9", bold = true },

      IlluminatedWordRead = { underline = true, bg = "<color>" },
      IlluminatedWordText = { underline = true, bg = "<color>" },
      IlluminatedWordWrite = { underline = true, bg = "<color>" },
    },
  },
}
