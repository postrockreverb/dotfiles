return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 300
  end,
  opts = {
    preset = "helix",
    icons = {
      mappings = false,
    },
  },
  keys = {
    { "<leader>q", "<cmd>quitall<cr>", desc = "Quit" },
    { "<leader>n", "<cmd>noh<cr>", desc = "No highlight" },
    { "<leader>c", "<cmd>bd<cr>", desc = "Close buffer" },
    { "<leader>C", "<cmd>%bd|e#|bd#<cr>", desc = "Close other buffers" },
  },
  config = function(_, opts)
    local wk = require("which-key")
    wk.setup(opts)
    wk.add({
      { "<leader>t", group = "Telescope" },
      { "<leader>g", group = "Git" },
    })
  end,
}
