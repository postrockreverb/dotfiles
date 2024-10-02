return {
  {
    "neovim/nvim-lspconfig",
    event = "VeryLazy",
  },
  {
    "williamboman/mason.nvim",
    cmd = {
      "Mason",
      "MasonUninstall",
      "MasonInstall",
      "MasonUpdate",
    },
    dependencies = {
      "williamboman/mason-lspconfig.nvim",
      "stevearc/conform.nvim",
      "zapling/mason-conform.nvim",
    },
  },
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason").setup()
      require("mason-lspconfig").setup({
        -- https://github.com/williamboman/mason-lspconfig.nvim?tab=readme-ov-file#available-lsp-servers
        ensure_installed = {
          "phpactor",
          "lua_ls",
          "svelte",
          "tailwindcss",
          "gopls",
          "ts_ls",
        },
      })

      require("lspconfig").phpactor.setup({})
      require("lspconfig").lua_ls.setup({})
      require("lspconfig").svelte.setup({
        on_attach = function(client)
          vim.api.nvim_create_autocmd("BufWritePost", {
            pattern = { "*.js", "*.ts" },
            callback = function(ctx)
              client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.file })
            end,
          })
          vim.api.nvim_create_autocmd({ "BufWrite" }, {
            pattern = { "+page.server.ts", "+page.ts", "+layout.server.ts", "+layout.ts" },
            command = "LspRestart svelte",
          })
        end,
      })
      require("lspconfig").tailwindcss.setup({})
      require("lspconfig").gopls.setup({})
      require("lspconfig").ts_ls.setup({})

      local wk = require("which-key")
      wk.add({
        { "K", vim.lsp.buf.hover },
        { "gd", vim.lsp.buf.definition },
        { "<leader>a", vim.lsp.buf.code_action, desc = "Code actions" },
        { "<leader>d", group = "Diagnostics" },
        { "<leader>do", vim.diagnostic.open_float, desc = "Open float" },
      })
    end,
  },
}
