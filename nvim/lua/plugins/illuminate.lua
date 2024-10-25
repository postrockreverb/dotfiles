return {
  "RRethy/vim-illuminate",
  event = "VimEnter",
  opts = {
    under_cursor = true,
    providers = {
      "lsp",
      "treesitter",
      "regex",
    },
    filetypes_denylist = {
      "NvimTree",
      "neo-tree",
      "dirvish",
      "fugitive",
      "alpha",
      "lazy",
      "neogitstatus",
      "Trouble",
      "lir",
      "Outline",
      "spectre_panel",
      "toggleterm",
      "DressingSelect",
      "TelescopePrompt",
    },
  },
  config = function(_, opts)
    require("illuminate").configure(opts)
  end,
}
