return {
  "f-person/auto-dark-mode.nvim",
  enabled = false,
  event = "VeryLazy",
  opts = {
    update_interval = 5000,
    set_dark_mode = function()
      vim.cmd([[colorscheme rose-pine-main]])
    end,
    set_light_mode = function()
      vim.cmd([[colorscheme rose-pine-dawn]])
    end,
  },
}
