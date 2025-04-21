return {
  "ibhagwan/fzf-lua",
  opts = {
    defaults = {
      file_icons = false,
      git_icons = false,
      color_icons = false,
    },
    oldfiles = {
      cwd_only = true,
      stat_file = true,
      include_current_session = true,
    },
    previewers = {
      bat = {
        theme = vim.g.shared_theme,
        args = "--color=always --style=numbers --tabs=2",
      },
      git_diff = {
        pager = false,
      },
    },
    fzf_opts = {
      ['--pointer=""'] = "",
    },
    winopts = {
      fullscreen = true,
      border = "none",
      preview = {
        default = "bat",
        layout = "vertical",
        vertical = "up",
        border = "noborder",
      },
    },
    keymap = {
      fzf = {
        true,
        ["ctrl-d"] = "preview-page-down",
        ["ctrl-u"] = "preview-page-up",
      },
    },
  },
  config = function(_, opts)
    local fzf = require("fzf-lua")

    local actions = require("fzf-lua.actions")
    opts.actions = {
      files = {
        true,
        ["ctrl-q"] = actions.file_sel_to_qf,
      },
    }

    fzf.setup(opts)

    local wk = require("which-key")
    wk.add({
      { "<leader>tf", fzf.files, desc = "Files" },
      { "<leader>tb", fzf.buffers, desc = "Buffers" },
      { "<leader>t/", fzf.live_grep, desc = "Grep" },
      { "<leader>tr", fzf.oldfiles, desc = "Recent files" },
      { "<leader>td", fzf.diagnostics_document, desc = "Diagnostics" },
      { "<leader>tD", fzf.diagnostics_workspace, desc = "Workspace diagnostics" },
      { "<leader>ts", fzf.lsp_document_symbols, desc = "Symbols" },
      { "<leader>tS", fzf.lsp_live_workspace_symbols, desc = "Workspace symbols" },
      { "<leader>tg", fzf.git_status, desc = "Git files" },
      { "<leader>tl", fzf.resume, desc = "Resume last" },
      { "gr", fzf.lsp_references, desc = "Lsp references" },
      { "gi", fzf.lsp_implementations, desc = "Lsp implementations" },
      { "gd", fzf.lsp_definitions, desc = "Lsp definitions" },
      { "gD", fzf.lsp_typedefs, desc = "Lsp type definitions" },
    })
  end,
}
