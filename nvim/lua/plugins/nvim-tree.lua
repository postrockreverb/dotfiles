local screen_width = vim.api.nvim_win_get_width(0)
local screen_height = vim.api.nvim_win_get_height(0)

local tree_width = math.floor(screen_width * 0.6)
local tree_height = math.floor(screen_height * 0.9)

return {
  "nvim-tree/nvim-tree.lua",
  cmd = { "NvimTreeToggle", "NvimTreeFocus", "NvimTreeFindFile" },
  keys = {
    { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Netrw" },
    { "<leader>-", "<cmd>NvimTreeFindFile<cr>", desc = "Focus file" },
  },
  config = function(_, opts)
    require("nvim-tree").setup(opts)
  end,
  opts = {
    filters = {
      dotfiles = false,
    },
    disable_netrw = true,
    hijack_cursor = true,
    sync_root_with_cwd = true,
    update_focused_file = {
      enable = true,
      update_root = false,
    },
    view = {
      number = true,
      relativenumber = true,
      float = {
        enable = true,
        open_win_config = {
          relative = "editor",
          border = "rounded",
          title = "",
          title_pos = "center",
          width = tree_width,
          height = tree_height,
          col = (screen_width - tree_width) / 2,
          row = (screen_height - tree_height) / 2,
        },
      },
    },
    renderer = {
      root_folder_label = false,
      highlight_git = true,
      indent_markers = { enable = true },
      icons = {
        git_placement = "right_align",
        glyphs = {
          folder = {
            arrow_closed = "", -- arrow when folder is closed
            arrow_open = "", -- arrow when folder is open
          },
          git = {
            unstaged = "",
            staged = "✓",
            unmerged = "",
            renamed = "➜",
            untracked = "󰓏",
            deleted = "",
            ignored = "◌",
          },
          -- default = "󰈚",
          -- folder = {
          --   default = "",
          --   empty = "",
          --   empty_open = "",
          --   open = "",
          --   symlink = "",
          -- },
        },
      },
    },
  },
}
