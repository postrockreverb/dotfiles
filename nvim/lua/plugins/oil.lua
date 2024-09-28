return {
  "stevearc/oil.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  enabled = false,
  config = function(_, opts)
    require("oil").setup(opts)

    local last = nil
    vim.api.nvim_create_autocmd("BufEnter", {
      pattern = "oil://*",
      callback = function(args)
        last = require("oil").get_current_dir()
      end,
    })

    local wk = require("which-key")
    wk.add({
      {
        "<leader>e",
        function()
          if last then
            require("oil").open(last)
          else
            vim.cmd([[Oil]])
          end
        end,
        desc = "Netrw",
      },
    })
  end,
  opts = {
    delete_to_trash = true,
    skip_confirm_for_simple_edits = false,
    prompt_save_on_select_new_entry = true,
    keymaps = {
      ["<leader>e"] = "actions.close",
      ["="] = {
        function()
          require("oil").open()
        end,
        mode = "n",
        nowait = true,
        desc = "Open current buffer directory",
      },
      ["<leader>tg"] = {
        function()
          _G.live_grep({ cwd = require("oil").get_current_dir() })
        end,
        mode = "n",
        nowait = true,
        desc = "Find files in the current directory",
      },
      ["<leader>tf"] = {
        function()
          _G.find_files({ cwd = require("oil").get_current_dir() })
        end,
        mode = "n",
        nowait = true,
        desc = "Find files in the current directory",
      },
    },
    view_options = {
      show_hidden = true,
    },
  },
}
