local hidden = {
  [".DS_Store"] = true,
  [".git"] = true,
  ["__pycache__"] = true,
}

-- Preview and split behaviour lifted from gitstager: the scroll keys drive the
-- preview rather than the listing, and <C-s> hands the preview split over to
-- the real file instead of stacking a third window beside it.
--
-- Width is deliberately dumb: set once, right after this file creates a split,
-- and never locked or watched. Afterwards vim's normal rules apply -- <C-w>=
-- equalizes everything, later splits re-share the space. Reopen the preview
-- to get the slice back.

-- How much of the screen oil keeps when this file opens a split next to it.
-- Below 1 it is read as a fraction of 'columns', 1 or more as a column count.
local oil_width = 0.2

local function width()
  local w = oil_width < 1 and vim.o.columns * oil_width or oil_width
  return math.max(20, math.floor(w))
end

-- Give `win` its slice. Floating oil sizes itself, and a lone window has
-- nothing to give.
local function set_width(win)
  if not vim.api.nvim_win_is_valid(win) or #vim.api.nvim_tabpage_list_wins(0) < 2 then
    return
  end
  if vim.api.nvim_win_get_config(win).relative ~= "" then
    return
  end
  vim.api.nvim_win_set_width(win, width())
end

local function preview_win()
  return require("oil.util").get_preview_win()
end

-- <C-p>. Oil's own action would do the toggling, but opening a preview is
-- async and its keymap form hands back no callback, so there would be no
-- moment at which the width could be set. Open it here instead; the close
-- half is the same test oil makes.
local function toggle_preview()
  local oil = require("oil")
  local entry = oil.get_cursor_entry()
  if not entry then
    return
  end

  local win = preview_win()
  if win and vim.w[win].oil_entry_id == entry.id then
    return vim.api.nvim_win_close(win, true)
  end

  local from = vim.api.nvim_get_current_win()
  oil.open_preview({}, function() set_width(from) end)
end

-- <C-s>. With a preview open, that split is already the window being read, so
-- the file goes there rather than into a new one.
local function select_split()
  local oil = require("oil")
  local from = vim.api.nvim_get_current_win()
  local target = preview_win()

  if not target then
    return oil.select({ vertical = true }, function() set_width(from) end)
  end

  -- What marks the window as a preview has to come off first, or oil takes it
  -- back down as soon as the cursor leaves the listing.
  vim.wo[target].previewwindow = false
  pcall(vim.api.nvim_win_del_var, target, "oil_preview")
  pcall(vim.api.nvim_win_del_var, target, "oil_entry_id")

  oil.select({
    vertical = true,
    -- Placing the buffer ourselves is what keeps the split count at two: oil
    -- would otherwise run :sbuffer and make a third window.
    handle_buffer_callback = function(bufnr)
      vim.api.nvim_win_set_buf(target, bufnr)
      if require("oil.util").is_oil_bufnr(bufnr) then
        oil.load_oil_buffer(bufnr)
      end
      vim.api.nvim_set_current_win(target)
    end,
  }, function() set_width(from) end)
end

-- The motion fed to the preview is the scroll itself, whatever key reaches it,
-- and falls through to the listing when there is no preview to scroll.
local function scroll(motion)
  return function()
    local win = preview_win()
    if not win then
      return vim.cmd("normal! " .. vim.keycode(motion))
    end
    vim.api.nvim_win_call(win, function() vim.cmd("normal! " .. vim.keycode(motion)) end)
  end
end

return {
  "stevearc/oil.nvim",
  init = function()
    vim.api.nvim_create_user_command("Ex", "Oil", { nargs = "?" }) --
  end,
  cmd = {
    "Oil",
  },
  opts = {
    columns = {},
    delete_to_trash = true,
    skip_confirm_for_simple_edits = false,
    prompt_save_on_select_new_entry = true,
    preview_win = {
      preview_method = "scratch",
    },
    keymaps = {
      ["q"] = { "actions.close", mode = "n" },
      ["<C-w>q"] = { "actions.close", mode = "n" },
      ["<C-p>"] = { toggle_preview, mode = "n", desc = "Toggle the preview" },
      ["<C-s>"] = { select_split, mode = "n", desc = "Open beside oil, over the preview" },
      ["<C-d>"] = { scroll("<C-d>"), mode = "n", desc = "Scroll the preview down" },
      ["<C-u>"] = { scroll("<C-u>"), mode = "n", desc = "Scroll the preview up" },
      ["<C-e>"] = { scroll("<C-e>"), mode = "n", desc = "Scroll the preview a line down" },
      ["<C-y>"] = { scroll("<C-y>"), mode = "n", desc = "Scroll the preview a line up" },
      ["<leader>t/"] = {
        function() require("fzf-lua").live_grep({ cwd = require("oil").get_current_dir() }) end,
        mode = "n",
        nowait = true,
        desc = "Find files in the current directory",
      },
      ["<leader>tf"] = {
        function() require("fzf-lua").files({ cwd = require("oil").get_current_dir() }) end,
        mode = "n",
        nowait = true,
        desc = "Find files in the current directory",
      },
    },
    view_options = {
      show_hidden = true,
      is_always_hidden = function(name, _)
        return hidden[name] --
      end,
    },
  },
}
