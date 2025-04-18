return {
  "nvim-lualine/lualine.nvim",
  opts = {
    options = {
      icons_enabled = false,
      globalstatus = true,
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
