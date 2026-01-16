return {
  -- lua
  stylua = {
    filetypes = { "lua" },
  },

  -- go
  gofumpt = {
    filetypes = { "go" },
  },
  goimports = {
    filetypes = { "go" },
  },
  templ = {
    filetypes = { "templ" },
  },

  -- rust
  rustfmt = {
    filetypes = { "rust" },
  },

  -- c
  ["clang-format"] = {
    filetypes = { "objc", "c", "cpp" },
  },

  -- js
  prettierd = {
    filetypes = {
      "typescript",
      "typescriptreact",
      "javascript",
      "javascriptreact",
      "html",
      "css",
      "svelte",
      "astro",
      "json",
    },
  },

  -- python
  ruff = {
    filetypes = { "python" },
  },

  -- shell
  shfmt = {
    filetypes = { "sh" },
  },
}
