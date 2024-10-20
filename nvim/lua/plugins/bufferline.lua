return {
  "akinsho/bufferline.nvim",
  version = "*",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  event = { "VimEnter" },
  keys = {
    { "<C-[>", "<cmd>BufferLineCyclePrev<cr>" },
    { "<C-]>", "<cmd>BufferLineCycleNext<cr>" },
    { "<C-A-[>", "<cmd>BufferLineMovePrev<cr>" },
    { "<C-A-]>", "<cmd>BufferLineMoveNext<cr>" },
  },
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
}
