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
  config = function(_, opts)
    local wk = require("which-key")
    wk.setup(opts)
    wk.add({
      -- groups
      { "<leader>t", group = "Telescope" },
      { "<leader>g", group = "Git" },
      { "<leader>d", group = "Diagnostics" },
      { "<leader>q", group = "Quickfix list" },
      { "<leader>b", group = "Buffers" },

      -- buffers
      { "<leader>bD", require("plugins.utils.buffers").clear_hidden, desc = "Close other" },
      { "<leader>bd", "<cmd>bp|sp|bn|bd<cr>", desc = "Close current" },

      -- quickfix list
      { "<leader>ql", "<cmd>copen<cr>", desc = "Open" },
      { "[q", "<cmd>cprev<cr>zz", desc = "Previous quickfix list item" },
      { "]q", "<cmd>cnext<cr>zz", desc = "Next quickfix list item" },
      { "[l", "<cmd>lprev<cr>zz", desc = "Previous quickfix list location" },
      { "]l", "<cmd>lnext<cr>zz", desc = "Next quickfix list location" },

      -- rename
      { "<leader>r", require("plugins.utils.renamer").rename_append, desc = "Rename append" },
      { "<leader>R", require("plugins.utils.renamer").rename_insert, desc = "Rename insert" },

      -- lsp
      { "K", vim.lsp.buf.hover },
      { "<leader>a", vim.lsp.buf.code_action, desc = "Actions", mode = { "n", "v" } },
      { "<leader>do", vim.diagnostic.open_float, desc = "Open float" },
    })
  end,
}
