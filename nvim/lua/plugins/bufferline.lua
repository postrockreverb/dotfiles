return {
  "akinsho/bufferline.nvim",
  version = "*",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  event = { "VimEnter" },
  init = function()
    vim.o.termguicolors = true
  end,
  opts = {
    options = {
      show_buffer_close_icons = false,
      diagnostics = "nvim_lsp",
      indicator = {
        style = "none",
      },
      separator_style = { "", "" },
    },
  },
  config = function(_, opts)
    require("bufferline").setup(opts)

    local wk = require("which-key")
    wk.add({
      { "<S-h>", "<cmd>BufferLineCyclePrev<cr>" },
      { "<S-l>", "<cmd>BufferLineCycleNext<cr>" },
    })
  end,
}
