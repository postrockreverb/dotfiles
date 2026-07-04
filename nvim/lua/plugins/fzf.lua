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
      include_current_session = false,
    },
    grep = {
      hidden = true,
    },
    previewers = {
      bat = {
        theme = vim.g.theme,
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
        vertical = "up:60%",
        border = "noborder",
      },
    },
    keymap = {
      fzf = {
        true,
        ["ctrl-d"] = "preview-half-page-down",
        ["ctrl-u"] = "preview-half-page-up",
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
    {
      "<leader>th",
      function()
        local marks = require("plugins.local.harpoon").list()
        if #marks == 0 then
          vim.notify("harpoon: no marks", vim.log.levels.WARN)
          return
        end

        local utils = require("fzf-lua.utils")
        local items, lookup = {}, {}
        for _, mark in ipairs(marks) do
          local key = mark.path .. ":" .. mark.line
          local display = mark.has_line and key or mark.path
          if mark.desc then
            display = display .. " " .. utils.ansi_from_hl("Directory", mark.desc)
          end
          table.insert(items, key .. ":" .. display)
          lookup[key] = mark
        end

        require("fzf-lua").fzf_exec(items, {
          prompt = "Harpoon > ",
          preview = "bat --style=numbers --color=always --highlight-line {2} {1}",
          actions = {
            ["default"] = function(selected)
              local key = selected[1] and selected[1]:match("^([^:]+:[^:]+)")
              local mark = key and lookup[key]
              if not mark then
                return
              end
              vim.cmd("edit +" .. mark.line .. " " .. vim.fn.fnameescape(mark.path) .. "| normal! zz")
            end,
          },
          fzf_opts = {
            ["--delimiter"] = ":",
            ["--preview-window"] = "up:+{2}-15:noborder",
            ["--with-nth"] = "3..",
            ["--ansi"] = "",
          },
        })
      end,
      desc = "Harpoon",
    },

    { "gr", function() require("fzf-lua").lsp_references() end, desc = "Lsp references" },
    { "gI", function() require("fzf-lua").lsp_implementations() end, desc = "Lsp implementations" },
    { "gd", function() require("fzf-lua").lsp_definitions() end, desc = "Lsp definitions" },
    { "gD", function() require("fzf-lua").lsp_typedefs() end, desc = "Lsp type definitions" },
  },
}
