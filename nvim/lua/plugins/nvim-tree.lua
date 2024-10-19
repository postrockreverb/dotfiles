local function custom_callback(callback_name)
  return string.format(":lua require('plugins.utils.nvim-tree').%s()<CR>", callback_name)
end

local HEIGHT_RATIO = 0.9
local WIDTH_RATIO = 0.6

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
  opts = function()
    local function my_on_attach(bufnr)
      local api = require("nvim-tree.api")

      local function opts(desc)
        return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
      end

      -- default mappings
      api.config.mappings.default_on_attach(bufnr)

      -- custom mappings
      vim.keymap.set("n", "d", api.fs.trash, opts("Trash"))
      vim.keymap.set("n", "y", api.fs.copy.node, opts("Copy"))
      vim.keymap.set("n", "c", api.fs.copy.filename, opts("Copy Name"))
      vim.keymap.set("n", "C", api.fs.copy.relative_path, opts("Copy Relative Path"))
      vim.keymap.set("n", "s", api.tree.search_node, opts("Search"))
      vim.keymap.set("n", "<esc>", api.tree.close, opts("Close"))
      vim.keymap.set("n", ".", api.tree.change_root_to_node, opts("CD"))
      vim.keymap.set("n", "<bs>", api.tree.change_root_to_parent, opts("Up"))
      vim.keymap.set("n", "q", function() end, opts("Noop"))
      vim.keymap.set("n", "tf", custom_callback("launch_find_files"), opts("Telescope Files"))
      vim.keymap.set("n", "tg", custom_callback("launch_live_grep"), opts("Telescope Grep"))
    end

    return {
      on_attach = my_on_attach,
      filters = {
        enable = false,
      },
      disable_netrw = true,
      hijack_cursor = true,
      sync_root_with_cwd = true,
      view = {
        number = true,
        relativenumber = true,
        float = {
          enable = true,
          open_win_config = function()
            local screen_w = vim.opt.columns:get()
            local screen_h = vim.opt.lines:get() - vim.opt.cmdheight:get()
            local window_w = screen_w * WIDTH_RATIO
            local window_h = screen_h * HEIGHT_RATIO
            local window_w_int = math.floor(window_w)
            local window_h_int = math.floor(window_h)
            local center_x = (screen_w - window_w) / 2
            local center_y = ((vim.opt.lines:get() - window_h) / 2) - vim.opt.cmdheight:get()
            return {
              border = "rounded",
              relative = "editor",
              row = center_y,
              col = center_x,
              width = window_w_int,
              height = window_h_int,
            }
          end,
        },
      },
      renderer = {
        root_folder_label = false,
        highlight_git = true,
        indent_markers = { enable = true, inline_arrows = true },
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
          },
        },
      },
    }
  end,
}
