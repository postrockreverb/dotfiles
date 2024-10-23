return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  ft = "markdown",
  opts = {},
  config = function(_, opts)
    local md = require("render-markdown")
    md.setup(opts)

    vim.cmd([[
      autocmd FileType markdown lua wkMarkdown()
    ]])

    _G.wkMarkdown = function()
      local wk = require("which-key")
      local buf = vim.api.nvim_get_current_buf()
      wk.add({
        { "<leader>m", md.toggle, desc = "Toggle markdown render", buffer = buf },
      })
    end
  end,
}
