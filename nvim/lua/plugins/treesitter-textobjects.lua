return {
  "nvim-treesitter/nvim-treesitter-textobjects",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
  },
  opts = {
    textobjects = {
      select = {
        enable = true,
        lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
        keymaps = {
          ["af"] = { query = "@function.outer", desc = "function" },
          ["if"] = { query = "@function.inner", desc = "inner function" },
          ["ac"] = { query = "@comment.outer", desc = "comment" },
        },
        selection_modes = {
          ["@function.outer"] = "V", -- linewise
        },
      },
      swap = {
        enable = true,
        swap_next = { ["]P"] = { query = "@parameter.inner", desc = "Swap with next parameter" } },
        swap_previous = { ["[P"] = { query = "@parameter.inner", desc = "Swap with previous parameter" } },
      },
    },
  },
  config = function(_, opts)
    local config = require("nvim-treesitter.configs")
    config.setup(opts)
  end,
}
