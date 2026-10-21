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
      keys = {
        Bslash = "\\",
      },
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
      { "<leader>c", group = "Change" },

      -- buffers
      { "<leader>b", group = "Buffers" },
      { "<leader>bp", require("plugins.utils.glow").preview, desc = "Preview in Glow" },

      -- quickfix list
      { "<leader>q", group = "Quickfix list" },
      { "<leader>ql", "<cmd>copen<cr>", desc = "Open" },
      { "<leader>qa", require("plugins.utils.qflist").toggle_current_line, desc = "Toggle current line" },
      { "<leader>qc", require("plugins.utils.qflist").clear, desc = "Clear" },
      { "[q", "<cmd>cprev<cr>zz", desc = "Previous quickfix list item" },
      { "]q", "<cmd>cnext<cr>zz", desc = "Next quickfix list item" },

      -- lsp
      { "K", vim.lsp.buf.hover },
      { "<leader>r", require("plugins.utils.renamer").rename_append, desc = "Rename append" },
      { "<leader>R", require("plugins.utils.renamer").rename_insert, desc = "Rename insert" },
      { "<leader>a", vim.lsp.buf.code_action, desc = "Code action", mode = { "n", "v" } },

      -- diagnostics
      { "<leader>d", group = "Diagnostics" },
      { "<leader>do", vim.diagnostic.open_float, desc = "Open float" },

      -- yank
      { "<leader>y", group = "Yank" },
      { "<leader>yp", require("plugins.utils.yank").path, desc = "File path" },
      { "<leader>yP", require("plugins.utils.yank").pathlinenr, desc = "File path with line number" },
      { "<leader>yq", require("plugins.utils.yank").qualified, desc = "Qualified symbol name" },

      -- windows
      { "<C-w>1", function() require("plugins.utils.splits").fraction(0.20) end, desc = "Window: 1/5 width" },
      { "<C-w>2", function() require("plugins.utils.splits").fraction(0.40) end, desc = "Window: 2/5 width" },
      { "<C-w>3", function() require("plugins.utils.splits").fraction(0.60) end, desc = "Window: 3/5 width" },
      { "<C-w>4", function() require("plugins.utils.splits").fraction(0.80) end, desc = "Window: 4/5 width" },

      -- cd to current file directory
      { "<leader>cd", function() vim.fn.feedkeys(":cd " .. vim.fn.expand("%:p:h")) end, desc = "Directory" },

      -- multicursors
      { "zq", group = "Multicursor" },
      { "zqn", desc = "Add cursors at search matches" },
      { "zqgn", desc = "Add cursors at search matches" },
      { "zq*", desc = "Add cursors at word matches" },
      { "zqw", desc = "Add cursors at every word" },
      { "Q", desc = "Toggle multicursor" },
      { "gQ", desc = "Restore multicursors" },
      { "q=", desc = "Toggle cursor follow mode" },
    })
  end,
}
