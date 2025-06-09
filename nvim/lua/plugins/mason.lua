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

  -- util
  bashls = {},
  dockerls = {},
}

local formatters_by_ft = {
  lua = { "stylua" },

  typescript = { "prettierd" },
  typescriptreact = { "prettierd", "rustywind" },
  javascript = { "prettierd" },
  javascriptreact = { "prettierd", "rustywind" },
  html = { "prettierd" },
  css = { "prettierd" },
  svelte = { "prettierd" },
  astro = { "prettierd" },

  go = { "gofumpt", "goimports" },
  objc = { "clang-format" },

  sh = { "shfmt" },
  markdown = { "prettierd" },
  json = { "prettierd" },
}

local linters_by_ft = {
  ["*"] = { "codespell" },
}

local formatters = {}
for _, fmts in pairs(formatters_by_ft) do
  for _, fmt in ipairs(fmts) do
    formatters[fmt] = true
  end
end

local linters = {}
for _, lts in pairs(linters_by_ft) do
  for _, lt in ipairs(lts) do
    linters[lt] = true
  end
end

local ensure_installed = {}
vim.list_extend(ensure_installed, vim.tbl_keys(servers))
vim.list_extend(ensure_installed, vim.tbl_keys(formatters))
vim.list_extend(ensure_installed, vim.tbl_keys(linters))

return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      { "williamboman/mason.nvim", opts = {} },
      "williamboman/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      { "j-hui/fidget.nvim", opts = {} }, -- Useful status updates for LSP.
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
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("lint").linters_by_ft = linters_by_ft

      local group = vim.api.nvim_create_augroup("lint", { clear = true })

      vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
        group = group,
        callback = function()
          local lint = require("lint")
          lint.try_lint()
          lint.try_lint("codespell")
        end,
      })
    end,
  },
}
