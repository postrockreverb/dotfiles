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
      diagnostics = false,
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
      { "<C-[>", "<cmd>BufferLineCyclePrev<cr>" },
      { "<C-]>", "<cmd>BufferLineCycleNext<cr>" },
      { "<C-A-[>", "<cmd>BufferLineMovePrev<cr>" },
      { "<C-A-]>", "<cmd>BufferLineMoveNext<cr>" },
    })
  end,
}
