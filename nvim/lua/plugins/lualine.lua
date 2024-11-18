return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    options = {
      globalstatus = true,
      disabled_filetypes = {
        statusline = { "NvimTree" },
      },
      component_separators = { left = "", right = "" },
      section_separators = { left = "", right = "" },
    },
    sections = {
      lualine_a = {},
      lualine_b = {
        { "buffers" },
      },
      lualine_c = {
        { "diagnostics", symbols = { error = "E", warn = "W", info = "I", hint = "H" } },
      },
      lualine_x = {},
      lualine_y = { "encoding" },
      lualine_z = {},
    },
  },
}
