local function with_theme(picker, theme)
  return function(opts)
    opts = opts or {}
    opts = vim.tbl_deep_extend("force", theme, opts)
    picker(opts)
  end
end

return {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.4",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "jonarrien/telescope-cmdline.nvim",
    "nvim-telescope/telescope-ui-select.nvim",
  },
  opts = {
    file_ignore_patterns = {
      "node%_modules/.*",
      "vendor/.*",
    },
    extensions = {
      ["ui-select"] = {
        require("telescope.themes").get_dropdown({}),
      },
    },
  },
  config = function(_, opts)
    local actions = require("telescope.actions")
    local layout_actions = require("telescope.actions.layout")
    opts.defaults = {
      mappings = {
        i = {
          ["<C-k>"] = actions.move_selection_previous, -- move to prev result
          ["<C-j>"] = actions.move_selection_next, -- move to next result
          ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist, -- send selected to quickfixlist
          ["<C-p>"] = layout_actions.toggle_preview,
        },
      },
    }

    local telescope = require("telescope")
    telescope.setup(opts)
    telescope.load_extension("ui-select")

    local themes = require("telescope.themes")
    local dropdown = themes.get_dropdown({
      layout_strategy = "vertical",
      layout_config = {
        prompt_position = "top",
        height = 0.95,
        width = 0.7,
        preview_height = 0.6,
      },
    })

    local builtin = require("telescope.builtin")
    _G.find_files = with_theme(builtin.find_files, dropdown)
    _G.live_grep = with_theme(builtin.live_grep, dropdown)

    local wk = require("which-key")
    wk.add({
      { "<leader>t", group = "Telescope" },
      { "<leader>tf", with_theme(builtin.find_files, dropdown), desc = "Files" },
      { "<leader>tb", with_theme(builtin.buffers, dropdown), desc = "Buffers" },
      { "<leader>tg", with_theme(builtin.live_grep, dropdown), desc = "Grep" },
      { "<leader>tr", with_theme(builtin.oldfiles, dropdown), desc = "Recent files" },
      { "<leader>td", with_theme(builtin.diagnostics), desc = "Diagnostics" },
      { "<leader>tl", builtin.resume, desc = "Resume last" },
      { "gr", builtin.lsp_references },
    })
  end,
}
