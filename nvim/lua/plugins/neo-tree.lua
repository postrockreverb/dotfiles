local function getTelescopeOpts(state, path)
  return {
    cwd = path,
    search_dirs = { path },
    attach_mappings = function(prompt_bufnr, map)
      local actions = require("telescope.actions")
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local action_state = require("telescope.actions.state")
        local selection = action_state.get_selected_entry()
        local filename = selection.filename
        if filename == nil then
          filename = selection[1]
        end
        -- any way to open the file without triggering auto-close event of neo-tree?
        require("neo-tree.sources.filesystem").navigate(state, state.path, filename)
      end)
      return true
    end,
  }
end

return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
    "nvim-telescope/telescope.nvim",
  },
  opts = {
    window = {
      position = "current",
    },
    event_handlers = {
      {
        event = "neo_tree_buffer_enter",
        handler = function()
          vim.cmd([[setlocal relativenumber]])
        end,
      },
    },
    default_component_configs = {
      indent = {
        with_markers = false,
      },
      git_status = {
        symbols = {
          -- Change type
          added = "", -- or "✚", but this is redundant info if you use git_status_colors on the name
          modified = "", -- or "", but this is redundant info if you use git_status_colors on the name
          deleted = "✖", -- this can only be used in the git_status source
          renamed = "󰁕", -- this can only be used in the git_status source
          -- Status type
          untracked = "",
          ignored = "",
          unstaged = "󰄱",
          staged = "",
          conflict = "",
        },
      },
      file_size = { enabled = false },
      type = { enabled = false },
      last_modified = { enabled = false },
      created = { enabled = false },
      symlink_target = { enabled = false },
    },
    filesystem = {
      filtered_items = {
        visible = true,
        hide_dotfiles = true,
        hide_gitignored = true,
        never_show = {
          ".git",
        },
      },
      window = {
        mappings = {
          ["<space>"] = "",
          ["tf"] = "telescope_find",
          ["tg"] = "telescope_grep",
        },
      },
    },
    commands = {
      telescope_find = function(state)
        local node = state.tree:get_node()
        local path = node:get_id()
        require("telescope.builtin").find_files(getTelescopeOpts(state, path))
      end,
      telescope_grep = function(state)
        local node = state.tree:get_node()
        local path = node:get_id()
        require("telescope.builtin").live_grep(getTelescopeOpts(state, path))
      end,
    },
  },
  config = function(_, opts)
    require("neo-tree").setup(opts)

    local wk = require("which-key")
    wk.add({
      { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Netrw" },
      { "<leader>-", "<cmd>Neotree reveal<cr>", desc = "Focus file" },
      { "<leader>b", "<cmd>Neotree toggle buffers<cr>", desc = "Buffers" },
      { "<leader>g", group = "Git" },
      { "<leader>gs", "<cmd>Neotree toggle git_status<cr>", desc = "Status" },
    })
  end,
}
