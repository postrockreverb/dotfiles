return {
  "neovim/nvim-lspconfig",
  dependencies = {
    { "williamboman/mason.nvim", opts = {} },
    "williamboman/mason-lspconfig.nvim",
  },
  config = function()
    local servers = {
      lua_ls = {
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
      },
      gopls = {
        settings = {
          gopls = {
            buildFlags = { "-tags=component" },
          },
        },
      },
      svelte = {
        on_attach = function(client)
          vim.api.nvim_create_autocmd("BufWritePost", {
            pattern = { "*.js", "*.ts" },
            callback = function(ctx) client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.file }) end,
          })
          vim.api.nvim_create_autocmd({ "BufWrite" }, {
            pattern = { "+page.server.ts", "+page.ts", "+layout.server.ts", "+layout.ts" },
            command = "LspRestart svelte",
          })
        end,
      },
      clangd = {
        filetypes = { "c", "cpp", "objc", "objcpp" },
      },
    }

    local ensure_installed = vim.tbl_keys(servers or {})
    vim.list_extend(ensure_installed, {
      "phpactor",
      "lua_ls",
      "svelte",
      "tailwindcss",
      "gopls",
      "ts_ls",
      "astro",
      "eslint",
      "dockerls",
      "ols",
      "clangd",
    })

    local original_capabilities = vim.lsp.protocol.make_client_capabilities()
    local capabilities = require("blink.cmp").get_lsp_capabilities(original_capabilities)

    require("mason-lspconfig").setup({
      ensure_installed = ensure_installed,
      automatic_enable = false,
    })

    for server_name, config in pairs(servers) do
      config.capabilities = vim.tbl_deep_extend("force", {}, capabilities, config.capabilities or {})
      require("lspconfig")[server_name].setup(config)
    end
  end,
}
