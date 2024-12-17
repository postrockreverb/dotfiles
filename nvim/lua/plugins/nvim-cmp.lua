return {
  "hrsh7th/nvim-cmp",
  event = "InsertEnter",
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "hrsh7th/cmp-cmdline",
  },
  config = function()
    local cmp = require("cmp")

    local snippets_paths = {
      vim.fn.stdpath("config") .. "/snippets/*\\.json",
      vim.fn.stdpath("config") .. "/snippets/*\\.code-snippets",
      vim.fn.getcwd() .. "/\\.vscode/*\\.code-snippets",
    }

    local snp = require("plugins.utils.snippets").source(snippets_paths)
    cmp.register_source("snp", snp)

    cmp.setup({
      mapping = cmp.mapping.preset.insert({
        ["<CR>"] = cmp.mapping.confirm({ select = true }),
        ["<C-j>"] = cmp.mapping.select_next_item(),
        ["<C-k>"] = cmp.mapping.select_prev_item(),
      }),
      sources = cmp.config.sources({
        { name = "nvim_lsp" }, -- lsp
        { name = "snp" }, -- snippets
        { name = "buffer" }, -- text within current buffer
        { name = "path" }, -- file system paths
      }),
    })
  end,
}
