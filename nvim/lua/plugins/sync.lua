return {
  "sync",
  dir = vim.fn.stdpath("config") .. "/lua/plugins/local/sync",
  cmd = {
    "Sync",
    "SyncGit",
  },
  config = function()
    local sync = require("plugins.local.sync")

    local script_path = sync.get_script_path(".sync")
    if not script_path then
      vim.notify(".sync script not found", vim.log.levels.ERROR)
      return
    end

    local root = sync.get_directory_from_path(script_path)

    local cmd = "bash " .. vim.fn.shellescape(script_path)
    local opts = {
      retries = 5,
      timeout_ms = 500,
      retry_msg = ".sync failed, retrying...",
      success_msg = ".sync finished successfully",
      failed_msg = ".sync failed",
    }

    vim.api.nvim_create_user_command("Sync", function()
      local file = sync.get_relative_buffer_path(root)
      if not file then
        vim.notify("unable to sync empty buffer", vim.log.levels.WARN)
        return
      end

      sync.run(cmd .. " " .. file, opts)
    end, { desc = "Run .sync for current buffer" })

    vim.api.nvim_create_user_command("SyncGit", function()
      local files = sync.get_changed_git_files()

      for _, file in ipairs(files.changed_files) do
        sync.run(cmd .. " " .. file, opts)
      end

      for _, file in ipairs(files.deleted_files) do
        sync.run(cmd .. " " .. file, opts)
      end
    end, { desc = "Run .sync for changed git files" })
  end,
}
