return {
  "rmagatti/auto-session",
  dependencies = {
    "nvim-telescope/telescope.nvim",
  },
  opts = {
    allowed_dirs = {
      "~/CloudStation/GitHub/*",
      "~/CloudStation/Obsidian",
      "~/.config/nvim",
    },
    args_allow_single_directory = false,
  },
  config = function(_, opts)
    require("auto-session").setup(opts)

    local wk = require("which-key")
    wk.add({
      { "<leader>t", group = "Telescope" },
      { "<leader>ts", "<cmd>SessionSearch<CR>", desc = "Sessions" },
    })
  end,
}
