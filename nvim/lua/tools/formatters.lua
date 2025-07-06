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

  -- c
  ["clang-format"] = {
    filetypes = { "objc", "c", "cpp" },
  },

  -- js
  biome = {
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

  -- shell
  shfmt = {
    filetypes = { "sh" },
  },
}
