return {
  "tanvirtin/vgit.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  event = { "BufReadPre", "BufNewFile" },
  keys = {
    { "<leader>gb", "<cmd>VGit buffer_gutter_blame_preview<cr>", desc = "Blame" },
    { "<leader>gz", "<cmd>VGit buffer_hunk_reset<cr>", desc = "Reset hunk" },
    { "<leader>gZ", "<cmd>VGit buffer_reset<cr>", desc = "Reset buffer" },
    { "<leader>gh", "<cmd>VGit buffer_hunk_preview<cr>", desc = "Preview hunk" },
    { "<leader>gd", "<cmd>VGit buffer_diff_preview<cr>", desc = "Buffer diff" },
  },
  opts = {
    settings = {
      live_blame = { enabled = false },
    },
  },
}
