return {
  "whatever",
  dir = vim.fn.stdpath("config") .. "/lua/plugins/local/whatever",
  config = function()
    local we = require("plugins.local.whatever") -- init

    local wk = require("which-key")
    wk.add({
      { "<leader>\\", we.insert, desc = "Insert whatever prompt" },
    })
  end,
}
