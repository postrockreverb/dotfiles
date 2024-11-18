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
  event = "VeryLazy",
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
      path_display = { "trancate" },
      mappings = {
        i = {
          ["<C-k>"] = actions.move_selection_previous, -- move to prev result
          ["<C-j>"] = actions.move_selection_next, -- move to next result
          ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist, -- send selected to quickfixlist
          ["<C-p>"] = layout_actions.toggle_preview,
          ["<C-c>"] = actions.delete_buffer,
          ["<C-s>"] = actions.toggle_selection,
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
      { "<leader>tf", with_theme(builtin.find_files, dropdown), desc = "Files" },
      { "<leader>tb", with_theme(builtin.buffers, dropdown), desc = "Buffers" },
      { "<leader>t/", with_theme(builtin.live_grep, dropdown), desc = "Grep" },
      { "<leader>tr", with_theme(builtin.oldfiles, dropdown), desc = "Recent files" },
      { "<leader>td", with_theme(builtin.diagnostics, dropdown), desc = "Diagnostics" },
      { "<leader>ts", with_theme(builtin.lsp_document_symbols, dropdown), desc = "Symbols" },
      { "<leader>tS", with_theme(builtin.lsp_dynamic_workspace_symbols, dropdown), desc = "Workspace symbols" },
      { "<leader>tg", with_theme(builtin.git_status, dropdown), desc = "Git files" },
      { "<leader>tl", builtin.resume, desc = "Resume last" },
      { "gr", with_theme(builtin.lsp_references, dropdown), desc = "Lsp references" },
      { "gi", with_theme(builtin.lsp_implementations, dropdown), desc = "Lsp references" },
      { "gd", with_theme(builtin.lsp_definitions, dropdown), desc = "Lsp references" },
      { "gD", with_theme(builtin.lsp_type_definitions, dropdown), desc = "Lsp references" },
    })
  end,
}
