return {
  "rsync-deploy",
  dir = vim.fn.stdpath("config") .. "/lua/plugins/local/rsync-deploy",
  keys = {
    { "<leader>s", function() require("plugins.local.rsync-deploy").sync() end, desc = "Sync to remote" },
  },
}
