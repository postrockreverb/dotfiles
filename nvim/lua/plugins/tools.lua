local tools = require("tools")

return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      { "williamboman/mason.nvim", opts = {} },
      "williamboman/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      "hrsh7th/nvim-cmp",
    },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      capabilities.textDocument.foldingRange = {
        dynamicRegistration = false,
        lineFoldingOnly = true,
      }

      require("mason-tool-installer").setup({
        ensure_installed = tools.ensure_installed,
      })

      for name, cfg in pairs(tools.servers) do
        cfg.capabilities = vim.tbl_deep_extend("force", {}, capabilities, cfg.capabilities or {})
        vim.lsp.config(name, cfg)
        vim.lsp.enable(name)
      end
    end,
  },
  {
    "stevearc/conform.nvim",
    cmd = { "ConformInfo" },
    keys = {
      { "<leader>l", function() require("conform").format() end, desc = "Format buffer", mode = { "n", "v" } }, -- TODO: format visual
    },
    opts = {
      formatters = tools.formatters_settings,
      formatters_by_ft = tools.formatters_by_ft,
    },
  },
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("lint").linters_by_ft = tools.linters_by_ft

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
