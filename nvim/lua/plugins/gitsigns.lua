local stage_hunk_v = function()
  require("gitsigns").stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) --
end

local reset_hunk_v = function()
  require("gitsigns").reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) --
end

local prev_hunk = function()
  if vim.wo.diff then
    vim.cmd.normal({ "[h", bang = true })
  else
    require("gitsigns").nav_hunk("prev")
  end
end

local next_hunk = function()
  if vim.wo.diff then
    vim.cmd.normal({ "]h", bang = true })
  else
    require("gitsigns").nav_hunk("next")
  end
end

return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  keys = {
    { "<leader>gh", function() require("gitsigns").preview_hunk_inline() end, desc = "Preview hunk" },
    { "<leader>gb", function() require("gitsigns").blame_line({ full = true }) end, desc = "Blame" },
    { "<leader>ga", function() require("gitsigns").stage_hunk() end, desc = "Stage hunk" },
    { "<leader>gz", function() require("gitsigns").reset_hunk() end, desc = "Reset hunk" },
    { "<leader>ga", stage_hunk_v, mode = "v", desc = "Stage hunk" },
    { "<leader>gz", reset_hunk_v, mode = "v", desc = "Reset hunk" },
    { "<leader>gZ", function() require("gitsigns").reset_buffer() end, desc = "Reset buffer" },
    { "[h", prev_hunk, desc = "Previous hunk" },
    { "]h", next_hunk, desc = "Next hunk" },
  },
  opts = {
    signs = {
      add = { text = "┃" },
      change = { text = "┃" },
      delete = { text = "_" },
      topdelete = { text = "‾" },
      changedelete = { text = "~" },
      untracked = { text = "┃" },
    },
    signs_staged_enable = false,
    attach_to_untracked = true,
  },
}
