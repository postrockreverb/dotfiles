return {
  "filipdutescu/renamer.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    {
      "<leader>r",
      "<cmd>lua require('renamer').rename({empty = false})<cr>",
      desc = "Rename append",
      mode = { "n", "v" },
    },
    {
      "<leader>R",
      "<cmd>lua require('renamer').rename({empty = true})<cr>",
      desc = "Rename insert",
      mode = { "n", "v" },
    },
  },
  opts = {
    with_popup = false,
  },
}
