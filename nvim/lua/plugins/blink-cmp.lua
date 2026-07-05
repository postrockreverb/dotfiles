return {
  "saghen/blink.cmp",
  -- optional: provides snippets for the snippet source
  dependencies = { "rafamadriz/friendly-snippets" },

  -- use a release tag to download pre-built binaries
  version = "1.*",

  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    -- 'default' (C-y to accept) plus the keys carried over from nvim-cmp:
    -- <CR> to accept, <C-j>/<C-k> to cycle. Tab/S-Tab jump snippets (preset).
    keymap = {
      preset = "default",
      ["<CR>"] = { "accept", "fallback" },
      ["<C-j>"] = { "select_next", "fallback" },
      ["<C-k>"] = { "select_prev", "fallback" },
    },

    appearance = {
      nerd_font_variant = "mono",
    },

    completion = {
      documentation = {
        auto_show = true,
        -- show docs beside the menu; 'e' (right/east) is tried first
        window = {
          direction_priority = {
            menu_north = { "e", "w", "n", "s" },
            menu_south = { "e", "w", "s", "n" },
          },
        },
      },
      menu = {
        draw = {
          -- label on the left, kind as text (Variable, Function, ...) on the right
          columns = {
            { "label", "label_description", gap = 1 },
            { "kind", gap = 1 },
          },
        },
      },
    },

    -- signature help: show the current function's parameters (with the active
    -- one highlighted) while typing arguments
    signature = { enabled = true },

    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
    },

    fuzzy = { implementation = "prefer_rust_with_warning" },
  },
  opts_extend = { "sources.default" },
}
