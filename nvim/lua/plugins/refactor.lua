return {
  "ThePrimeagen/refactoring.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  cmd = "Refactor",
  keys = {
    {
      "<leader>ar",
      function()
        require("refactoring").select_refactor()
      end,
      desc = "Refactor",
      mode = { "n", "v" },
    },
  },
  config = function()
    require("refactoring").setup()
  end,
}
