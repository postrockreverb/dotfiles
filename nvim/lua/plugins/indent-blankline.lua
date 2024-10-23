return {
  "lukas-reineke/indent-blankline.nvim",
  main = "ibl",
  event = "VimEnter",
  opts = {
    enabled = true,
    indent = {
      char = "▏",
    },
    scope = {
      enabled = false,
      show_start = false,
    },
  },
}
