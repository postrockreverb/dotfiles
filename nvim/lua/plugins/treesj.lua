return {
  "Wansmer/treesj",
  keys = {
    { "<leader>j", "<cmd>TSJToggle<cr>", desc = "Join/split code" },
  },
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  opts = function()
    local lang_utils = require("treesj.langs.utils")
    return {
      use_default_keymaps = false,
      max_join_length = 512,
      langs = {
        ron = {
          struct = lang_utils.set_preset_for_args({
            both = { shrink_node = { from = "(", to = ")" } },
            split = { last_separator = true },
          }),
          tuple = lang_utils.set_preset_for_args({
            split = { last_separator = true },
          }),
          array = lang_utils.set_preset_for_list({
            join = { space_in_brackets = false },
          }),
          map = lang_utils.set_preset_for_dict(),
          struct_entry = { target_nodes = { "struct", "tuple", "array", "map" } },
          map_entry = { target_nodes = { "struct", "tuple", "array", "map" } },
        },
      },
    }
  end,
}
