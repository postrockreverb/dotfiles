return {
  "tanvirtin/vgit.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  init = function()
    vim.o.updatetime = 300
    vim.wo.signcolumn = "yes"
  end,
  opts = {
    settings = {
      live_blame = {
        enabled = false,
      },
    },
  },
  config = function(_, opts)
    local vgit = require("vgit")
    vgit.setup(opts)

    local wk = require("which-key")
    wk.add({
      { "<leader>gb", vgit.buffer_gutter_blame_preview, desc = "Blame" },
      { "<leader>gz", vgit.buffer_hunk_reset, desc = "Reset hunk" },
      { "<leader>gZ", vgit.buffer_reset, desc = "Reset buffer" },
      { "<leader>gh", vgit.buffer_hunk_preview, desc = "Preview hunk" },
      { "<leader>gd", vgit.buffer_diff_preview, desc = "Buffer diff" },
      { "<leader>gD", vgit.project_diff_preview, desc = "Project diff" },
    })
  end,
}
