local vaultRoot = vim.fn.expand("~") .. "/CloudStation/Obsidian"
local vaultFilesPattern = vaultRoot .. "/*.md"

return {
  "epwalsh/obsidian.nvim",
  version = "*",
  lazy = true,
  ft = "markdown",
  event = {
    "BufReadPre " .. vaultFilesPattern,
    "BufNewFile " .. vaultFilesPattern,
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  opts = {
    workspaces = {
      {
        name = "Obsidian",
        path = vaultRoot,
      },
    },
    completion = {
      nvim_cmp = true,
      min_chars = 2,
    },
    ui = {
      enable = false,
    },
  },
}
