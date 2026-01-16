return {
  "whatever",
  dir = vim.fn.stdpath("config") .. "/lua/plugins/local/whatever",
  keys = {
    { "<leader>\\", require("plugins.local.whatever").insert, desc = "Insert whatever prompt" },
  },
}
