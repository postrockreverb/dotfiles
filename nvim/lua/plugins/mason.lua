return {
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
}
