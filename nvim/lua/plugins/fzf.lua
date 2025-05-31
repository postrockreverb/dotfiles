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
        pager = "delta --color-only",
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
  end,
  keys = {
    { "<leader>tf", function() require("fzf-lua").files() end, desc = "Files" },
    { "<leader>tb", function() require("fzf-lua").buffers() end, desc = "Buffers" },
    { "<leader>t/", function() require("fzf-lua").live_grep() end, desc = "Grep" },
    { "<leader>tr", function() require("fzf-lua").oldfiles() end, desc = "Recent files" },
    { "<leader>td", function() require("fzf-lua").diagnostics_document() end, desc = "Diagnostics" },
    { "<leader>tD", function() require("fzf-lua").diagnostics_workspace() end, desc = "Workspace diagnostics" },
    { "<leader>ts", function() require("fzf-lua").lsp_document_symbols() end, desc = "Symbols" },
    { "<leader>tS", function() require("fzf-lua").lsp_live_workspace_symbols() end, desc = "Workspace symbols" },
    { "<leader>tg", function() require("fzf-lua").git_status() end, desc = "Git files" },
    { "<leader>tl", function() require("fzf-lua").resume() end, desc = "Resume last" },
    {
      "<leader>tz",
      function()
        require("fzf-lua").zoxide({
          actions = {
            enter = function(selected)
              local path = selected[1]:match("[^\t]+$") or selected[1]
              vim.cmd("Oil " .. path)
            end,
          },
        })
      end,
      desc = "Zoxide",
    },

    { "gr", function() require("fzf-lua").lsp_references() end, desc = "Lsp references" },
    { "gi", function() require("fzf-lua").lsp_implementations() end, desc = "Lsp implementations" },
    { "gd", function() require("fzf-lua").lsp_definitions() end, desc = "Lsp definitions" },
    { "gD", function() require("fzf-lua").lsp_typedefs() end, desc = "Lsp type definitions" },
  },
}
