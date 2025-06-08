local servers = {
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
      },
    },
  },

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
  eslint = {},

  -- util
  bashls = {},
  dockerls = {},
}

local formatters_by_ft = {
  lua = { "stylua" },

  typescript = { "prettierd", "prettier" },
  typescriptreact = { "prettierd", "prettier", "rustywind" },
  javascript = { "prettierd", "prettier" },
  javascriptreact = { "prettierd", "prettier", "rustywind" },
  html = { "prettierd", "prettier" },
  css = { "prettierd", "prettier" },
  svelte = { "prettierd", "prettier" },
  astro = { "prettierd", "prettier" },

  go = { "gofumpt", "goimports" },
  objc = { "clang-format" },

  sh = { "shfmt" },
  markdown = { "prettierd", "prettier" },
  json = { "prettierd", "prettier" },
}

local formatters = {}
for _, fmts in pairs(formatters_by_ft) do
  for _, fmt in ipairs(fmts) do
    formatters[fmt] = true
  end
end

local ensure_installed = vim.tbl_extend(
  "force",
  -- ensure installed servers here
  vim.tbl_keys(servers),
  vim.tbl_keys(formatters)
)

return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      { "williamboman/mason.nvim", opts = {} },
      "williamboman/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
    },
    config = function()
      local original_capabilities = vim.lsp.protocol.make_client_capabilities()
      local capabilities = require("blink.cmp").get_lsp_capabilities(original_capabilities)

      require("mason-tool-installer").setup({
        ensure_installed = ensure_installed,
      })

      require("mason-lspconfig").setup({
        ensure_installed = {}, -- explicitly set to an empty table (installs via mason-tool-installer)
        automatic_enable = false,
      })

      for server_name, config in pairs(servers) do
        config.capabilities = vim.tbl_deep_extend("force", {}, capabilities, config.capabilities or {})
        require("lspconfig")[server_name].setup(config)
      end
    end,
  },
  {
    "stevearc/conform.nvim",
    cmd = {
      "ConformInfo",
    },
    keys = {
      { "<leader>l", "<cmd>lua require('conform').format()<cr>", desc = "Format buffer", mode = { "n", "v" } },
    },
    opts = {
      formatters_by_ft = formatters_by_ft,
    },
  },
}
