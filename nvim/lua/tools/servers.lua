return {
  -- lua
  lua_ls = {
    settings = {
      Lua = {
        runtime = { version = "LuaJIT" },
        diagnostics = { globals = { "vim", "require" } },
        workspace = { library = vim.api.nvim_get_runtime_file("", true) },
        telemetry = { enable = false },
      },
    },
  },

  -- go
  gopls = {
    settings = {
      gopls = {
        buildFlags = { "-tags=component" },
        diagnosticsTrigger = "Save",
        directoryFilters = { "-**/vendor", "-**/node_modules" },
        semanticTokens = true,
      },
    },
  },
  templ = {},

  -- c
  clangd = {
    filetypes = { "c", "cpp", "objc", "objcpp" },
  },

  -- js
  ts_ls = {},
  tailwindcss = {},
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
  astro = {},

  -- python
  pyright = {},

  -- shell
  bashls = {},

  -- docker
  dockerls = {},
}
