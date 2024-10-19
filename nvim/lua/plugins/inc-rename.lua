return {
  "smjonas/inc-rename.nvim",
  opts = {
    cmd_name = "Rename",
  },
  config = function(_, opts)
    require("inc_rename").setup(opts)

    local wk = require("which-key")
    wk.add({ "<leader>r", ":Rename ", desc = "Rename" })
  end,
}
