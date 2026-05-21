return {
  "nvim-treesitter/nvim-treesitter",
  lazy = false,
  branch = "main",
  build = ":TSUpdate",
  init = function()
    vim.api.nvim_create_autocmd("FileType", {
      callback = function()
        -- Enable treesitter highlighting and disable regex syntax
        pcall(vim.treesitter.start)
        -- Enable treesitter-based indentation
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })

    local ensure_installed = {
      "markdown",
      "markdown_inline",
      "lua",
      "svelte",
      "typescript",
      "tsx",
      "css",
      "scss",
      "bash",
      "dockerfile",
      "gitignore",
      "go",
      "rust",
      "json",
      "astro",
      "templ",
      "c",
      "cpp",
      "python",
    }

    local already_installed = require("nvim-treesitter.config").get_installed()
    local parsers_to_install = vim
      .iter(ensure_installed)
      :filter(function(parser) return not vim.tbl_contains(already_installed, parser) end)
      :totable()

    require("nvim-treesitter").install(parsers_to_install)
  end,
}
