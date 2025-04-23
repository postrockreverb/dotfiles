return {
  {
    "zapling/mason-conform.nvim",
    opts = {
      ensure_installed = {
        "stylua",
        -- "php_cs_fixer",
        "prettierd",
        "prettier",
        "rustywind",
        "gofumpt",
        "goimports",
      },
      automatic_installation = true,
      quiet_mode = false,
    },
  },
  {
    "stevearc/conform.nvim",
    keys = {
      { "<leader>l", "<cmd>lua require('conform').format()<cr>", desc = "Format buffer", mode = { "n", "v" } },
    },
    opts = {
      -- https://github.com/stevearc/conform.nvim?tab=readme-ov-file#formatters
      formatters_by_ft = {
        lua = { "stylua" },
        -- php = { "php_cs_fixer" },
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
        sh = { "shfmt" },
      },
    },
  },
}
