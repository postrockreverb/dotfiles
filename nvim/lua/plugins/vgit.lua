return {
  "tanvirtin/vgit.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  event = "VimEnter",
  keys = {
    { "<leader>gb", "<cmd>VGit buffer_gutter_blame_preview<cr>", desc = "Blame" },
    { "<leader>gz", "<cmd>VGit buffer_hunk_reset<cr>", desc = "Reset hunk" },
    { "<leader>gZ", "<cmd>VGit buffer_reset<cr>", desc = "Reset buffer" },
    { "<leader>gh", "<cmd>VGit buffer_hunk_preview<cr>", desc = "Preview hunk" },
    { "<leader>gd", "<cmd>VGit buffer_diff_preview<cr>", desc = "Buffer diff" },
    { "<leader>gD", "<cmd>VGit project_diff_preview<cr>", desc = "Project diff" },
  },
  init = function()
    vim.o.updatetime = 300
    vim.wo.signcolumn = "yes"
  end,
  opts = {
    settings = {
      live_blame = { enabled = false },
    },
  },
}
