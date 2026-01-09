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
    win = {
      border = "none",
    },
  },
  config = function(_, opts)
    local wk = require("which-key")
    wk.setup(opts)
    wk.add({
      -- groups
      { "<leader>t", group = "Telescope" },
      { "<leader>g", group = "Git" },

      -- buffers
      { "<leader>b", group = "Buffers" },
      { "<leader>bp", '<cmd>term glow "%"<cr>', desc = "Preview in Glow" },

      -- quickfix list
      { "<leader>q", group = "Quickfix list" },
      { "<leader>ql", "<cmd>copen<cr>", desc = "Open" },
      { "[q", "<cmd>cprev<cr>zz", desc = "Previous quickfix list item" },
      { "]q", "<cmd>cnext<cr>zz", desc = "Next quickfix list item" },

      -- lsp
      { "K", vim.lsp.buf.hover },
      { "<leader>r", require("plugins.utils.renamer").rename_append, desc = "Lsp rename append" },
      { "<leader>R", require("plugins.utils.renamer").rename_insert, desc = "Lsp rename insert" },
      { "<leader>a", vim.lsp.buf.code_action, desc = "Lsp code action", mode = { "n", "v" } },

      -- diagnostics
      { "<leader>d", group = "Diagnostics" },
      { "<leader>do", vim.diagnostic.open_float, desc = "Open float" },

      -- yank
      { "<leader>y", group = "Yank" },
      { "<leader>yp", require("plugins.utils.yank").path, desc = "File path" },
      { "<leader>yP", require("plugins.utils.yank").pathlinenr, desc = "File path with line number" },

      -- windows
      { "<leader>w", group = "Window" },
      { "<leader>w2", function() require("plugins.utils.splits").fraction(0.50) end, desc = "Window: 1/2 width" },
      { "<leader>w3", function() require("plugins.utils.splits").fraction(0.34) end, desc = "Window: 1/3 width" },
    })
  end,
}
