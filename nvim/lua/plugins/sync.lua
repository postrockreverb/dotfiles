return {
  "sync",
  dir = vim.fn.stdpath("config") .. "/lua/plugins/local/sync",
  cmd = {
    "Sync",
  },
  config = function()
    local sync = require("plugins.local.sync")

    local script_path = sync.get_script_path(".sync")
    if not script_path then
      vim.notify(".sync script not found", vim.log.levels.ERROR)
      return
    end

    local cmd = "bash " .. vim.fn.shellescape(script_path)
    local opts = {
      retries = 5,
      timeout_ms = 500,
      retry_msg = ".sync failed, retrying...",
      success_msg = ".sync finished successfully",
      failed_msg = ".sync failed",
    }
    vim.api.nvim_create_user_command("Sync", function()
      sync.run(cmd, opts)
    end, { desc = "Run .sync" })
  end,
}
