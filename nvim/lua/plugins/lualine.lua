return {
  "nvim-lualine/lualine.nvim",
  -- enabled = false,
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    options = {
      globalstatus = true,
      component_separators = { left = "", right = "" },
      section_separators = { left = "", right = "" },
    },
    sections = {
      lualine_a = {},
      lualine_b = {
        { "filename", path = 1 },
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
