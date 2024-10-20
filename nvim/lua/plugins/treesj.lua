return {
  "Wansmer/treesj",
  keys = {
    { "<leader>j", "<cmd>TSJToggle<cr>", desc = "Join/split code" },
  },
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  opts = { use_default_keymaps = false },
}
