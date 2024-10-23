return {
  "davidmh/mdx.nvim",
  config = true,
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  ft = "mdx",
  init = function()
    vim.filetype.add({
      extension = {
        mdx = "mdx",
      },
    })
  end,
}
