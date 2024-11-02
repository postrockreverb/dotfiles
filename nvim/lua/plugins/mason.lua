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
    keys = {
      { "K", vim.lsp.buf.hover },
      { "gd", vim.lsp.buf.definition },
      { "<leader>aa", vim.lsp.buf.code_action, desc = "Actions" },
      { "<leader>do", vim.diagnostic.open_float, desc = "Open float" },
    },
    opts = {
      -- https://github.com/williamboman/mason-lspconfig.nvim?tab=readme-ov-file#available-lsp-servers
      ensure_installed = {
        "phpactor",
        "lua_ls",
        "svelte",
        "tailwindcss",
        "gopls",
        "ts_ls",
        "astro",
      },
    },
    config = function(_, opts)
      require("mason").setup()
      require("mason-lspconfig").setup(opts)

      require("lspconfig").phpactor.setup({})
      require("lspconfig").lua_ls.setup({
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = {
              globals = { "vim", "require" },
            },
            workspace = {
              library = vim.api.nvim_get_runtime_file("", true),
            },
            telemetry = { enable = false },
          },
        },
      })
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
      require("lspconfig").astro.setup({})
    end,
  },
}
