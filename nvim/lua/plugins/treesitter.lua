return {
  "nvim-treesitter/nvim-treesitter",
  event = { "BufReadPost", "BufNewFile" },
  cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
  build = ":TSUpdate",
  opts = {
    -- https://github.com/nvim-treesitter/nvim-treesitter?tab=readme-ov-file#supported-languages
    ensure_installed = {
      "php",
      "lua",
      "svelte",
      "typescript",
      "tsx",
      "css",
      "scss",
      "bash",
      "dockerfile",
      "gitignore",
      "go",
      "json",
      "astro",
    },
    sync_install = false,
    auto_install = true,
    highlight = {
      enable = true,
      use_languagetree = true,
    },
    indent = { enable = true },
  },
  config = function(_, opts) require("nvim-treesitter.configs").setup(opts) end,
}
