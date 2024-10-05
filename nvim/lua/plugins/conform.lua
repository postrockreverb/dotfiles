return {
  {
    "zapling/mason-conform.nvim",
    config = function()
      require("mason-conform").setup({
        ensure_installed = {
          "stylua",
          "php_cs_fixer",
          "prettierd",
          "prettier",
          "rustywind",
          "gofumpt",
          "goimports",
        },
        automatic_installation = true,
        quiet_mode = false,
      })
    end,
  },
  {
    "stevearc/conform.nvim",
    config = function()
      local conform = require("conform")

      conform.setup({
        -- https://github.com/stevearc/conform.nvim?tab=readme-ov-file#formatters
        formatters_by_ft = {
          lua = { "stylua" },
          php = { "php_cs_fixer" },
          typescript = { "prettierd", "prettier" },
          typescriptreact = { "prettierd", "prettier", "rustywind" },
          javascript = { "prettierd", "prettier" },
          javascriptreact = { "prettierd", "prettier", "rustywind" },
          json = { "prettierd", "prettier" },
          html = { "prettierd", "prettier" },
          css = { "prettierd", "prettier" },
          svelte = { "prettierd", "prettier" },
          go = { "gofumpt", "goimports" },
          markdown = { "prettierd", "prettier" },
          astro = { "prettierd", "prettier" },
        },
      })

      local wk = require("which-key")
      wk.add({ "<leader>l", conform.format, desc = "Format buffer", mode = { "n", "v" } })
    end,
  },
}
