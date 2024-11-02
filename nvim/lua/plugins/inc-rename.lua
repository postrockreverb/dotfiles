return {
  "smjonas/inc-rename.nvim",
  opts = {
    cmd_name = "Rename",
  },
  keys = {
    {
      "<leader>r",
      function()
        return ":Rename " .. vim.fn.expand("<cword>")
      end,
      expr = true,
      desc = "Rename append",
    },
    { "<leader>R", ":Rename ", desc = "Rename insert" },
  },
}
