return {
  "rmagatti/auto-session",
  enabled = false,
  lazy = false,
  dependencies = {
    "nvim-telescope/telescope.nvim",
  },
  keys = {
    { "<leader>t.", "<cmd>SessionSearch<CR>", desc = "Sessions" },
  },
  opts = {
    allowed_dirs = {
      "~/CloudStation/GitHub/*",
      "~/CloudStation/Obsidian",
      "~/.config/nvim",
    },
    args_allow_single_directory = false,
  },
}
