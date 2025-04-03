return {
  "stevearc/oil.nvim",
  init = function()
    vim.api.nvim_create_user_command("Ex", "Oil", { nargs = "?" })
  end,
  opts = {
    columns = {},
    delete_to_trash = true,
    skip_confirm_for_simple_edits = false,
    prompt_save_on_select_new_entry = true,
    keymaps = {
      ["<C-w>q"] = { "actions.close", mode = "n" },
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
