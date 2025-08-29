local helpers = require("plugins.local.export-colorscheme.helpers")

-- Kitty theme template based on official format
-- https://sw.kovidgoyal.net/kitty/kittens/themes/
local template = [[
# vim:ft=kitty

## name: $name
## author: $author
## license: $license
## upstream: $upstream
## blurb: $blurb

# The basic colors
foreground                      $fg
background                      $bg
selection_foreground            $selection_fg
selection_background            $selection_bg

# Cursor colors
cursor                          $cursor_bg
cursor_text_color               $cursor_fg

# URL underline color when hovering with mouse
url_color                       $url

# kitty window border colors
active_border_color             $border_active
inactive_border_color           $border_inactive
bell_border_color               $border_bell

# OS Window titlebar colors
wayland_titlebar_color          $titlebar_bg
macos_titlebar_color            $titlebar_bg

# Tab bar colors
active_tab_foreground           $tab_active_fg
active_tab_background           $tab_active_bg
inactive_tab_foreground         $tab_inactive_fg
inactive_tab_background         $tab_inactive_bg
tab_bar_background              $tab_bar_bg
tab_bar_margin_color            $tab_bar_margin

# Colors for marks (marked text in the terminal)
mark1_foreground                $mark1_fg
mark1_background                $mark1_bg
mark2_foreground                $mark2_fg
mark2_background                $mark2_bg
mark3_foreground                $mark3_fg
mark3_background                $mark3_bg

# The basic 16 colors

# black
color0                          $black
color8                          $bright_black

# red
color1                          $red
color9                          $bright_red

# green
color2                          $green
color10                         $bright_green

# yellow
color3                          $yellow
color11                         $bright_yellow

# blue
color4                          $blue
color12                         $bright_blue

# magenta
color5                          $magenta
color13                         $bright_magenta

# cyan
color6                          $cyan
color14                         $bright_cyan

# white
color7                          $white
color15                         $bright_white

# Extended colors can be set as color16 to color255]]

local m = {}

-- Helper function to get color from highlight group
local function get_hl_color(group, attr)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
  if ok and hl[attr] then
    return string.format("#%06x", hl[attr])
  end
  return nil
end

-- Helper function to get terminal color
local function get_terminal_color(index)
  local var_name = "terminal_color_" .. index
  local color = vim.g[var_name]
  if color then
    return color
  end
  return nil
end

-- Helper function to ensure color has # prefix
local function ensure_hex(color)
  if color and not color:match("^#") then
    return "#" .. color
  end
  return color
end

-- Extract colors from the current Neovim colorscheme
local function extract_colors()
  local colors = {}

  -- Get colorscheme name
  colors.name = vim.g.colors_name or "neovim"
  colors.author = "Auto-generated from Neovim"
  colors.license = "MIT"
  colors.upstream = "https://github.com/neovim/neovim"
  colors.blurb = string.format("Exported from %s Neovim colorscheme", colors.name)

  -- Basic colors from Normal highlight group
  colors.fg = get_hl_color("Normal", "fg") or "#d0d0d0"
  colors.bg = get_hl_color("Normal", "bg") or "#1c1c1c"

  -- Selection colors from Visual highlight group
  local visual_bg = get_hl_color("Visual", "bg")
  local visual_fg = get_hl_color("Visual", "fg")
  colors.selection_bg = visual_bg or "#404040"
  colors.selection_fg = visual_fg or "none"

  -- Cursor colors
  local cursor_bg = get_hl_color("Cursor", "bg")
  local cursor_fg = get_hl_color("Cursor", "fg")
  colors.cursor_bg = cursor_bg or colors.fg
  colors.cursor_fg = cursor_fg or colors.bg

  -- URL color
  colors.url = get_hl_color("Underlined", "fg") or "#0087bd"

  -- Border colors
  colors.border_active = get_hl_color("VertSplit", "fg") or get_hl_color("WinSeparator", "fg") or "#444444"
  colors.border_inactive = get_hl_color("NormalNC", "fg") or get_hl_color("WinSeparator", "fg") or "#303030"
  colors.border_bell = get_hl_color("WarningMsg", "fg") or get_hl_color("DiagnosticWarn", "fg") or "#ffaf00"

  -- Titlebar colors
  colors.titlebar_bg = get_hl_color("Title", "bg") or get_hl_color("StatusLine", "bg") or colors.bg

  -- Tab bar colors
  colors.tab_active_fg = get_hl_color("TabLineSel", "fg") or colors.fg
  colors.tab_active_bg = get_hl_color("TabLineSel", "bg") or "#404040"
  colors.tab_inactive_fg = get_hl_color("TabLine", "fg") or "#808080"
  colors.tab_inactive_bg = get_hl_color("TabLine", "bg") or "#303030"
  colors.tab_bar_bg = get_hl_color("TabLineFill", "bg") or "#202020"
  colors.tab_bar_margin = colors.tab_bar_bg

  -- Mark colors (using diff highlight groups)
  colors.mark1_fg = get_hl_color("DiffAdd", "fg") or "#87d787"
  colors.mark1_bg = get_hl_color("DiffAdd", "bg") or "#005f00"
  colors.mark2_fg = get_hl_color("DiffChange", "fg") or "#87afff"
  colors.mark2_bg = get_hl_color("DiffChange", "bg") or "#005f87"
  colors.mark3_fg = get_hl_color("DiffDelete", "fg") or "#d78787"
  colors.mark3_bg = get_hl_color("DiffDelete", "bg") or "#5f0000"

  -- Terminal colors (0-15)
  -- Try to get from vim.g.terminal_color_X first, then fallback to common highlight groups

  -- Black (0, 8)
  colors.black = get_terminal_color(0) or get_hl_color("Black", "fg") or "#000000"
  colors.bright_black = get_terminal_color(8) or get_hl_color("DarkGray", "fg") or "#808080"

  -- Red (1, 9)
  colors.red = get_terminal_color(1) or get_hl_color("Red", "fg") or get_hl_color("DiagnosticError", "fg") or "#d70000"
  colors.bright_red = get_terminal_color(9) or get_hl_color("LightRed", "fg") or "#ff5f5f"

  -- Green (2, 10)
  colors.green = get_terminal_color(2) or get_hl_color("Green", "fg") or get_hl_color("DiagnosticOk", "fg") or "#00af00"
  colors.bright_green = get_terminal_color(10) or get_hl_color("LightGreen", "fg") or "#5fdf5f"

  -- Yellow (3, 11)
  colors.yellow = get_terminal_color(3) or get_hl_color("Yellow", "fg") or get_hl_color("DiagnosticWarn", "fg") or "#d7af00"
  colors.bright_yellow = get_terminal_color(11) or get_hl_color("LightYellow", "fg") or "#ffff5f"

  -- Blue (4, 12)
  colors.blue = get_terminal_color(4) or get_hl_color("Blue", "fg") or get_hl_color("DiagnosticInfo", "fg") or "#0087d7"
  colors.bright_blue = get_terminal_color(12) or get_hl_color("LightBlue", "fg") or "#5fafff"

  -- Magenta (5, 13)
  colors.magenta = get_terminal_color(5) or get_hl_color("Magenta", "fg") or get_hl_color("Statement", "fg") or "#af00af"
  colors.bright_magenta = get_terminal_color(13) or get_hl_color("LightMagenta", "fg") or "#ff5fff"

  -- Cyan (6, 14)
  colors.cyan = get_terminal_color(6) or get_hl_color("Cyan", "fg") or get_hl_color("Function", "fg") or "#00afd7"
  colors.bright_cyan = get_terminal_color(14) or get_hl_color("LightCyan", "fg") or "#5fdfff"

  -- White (7, 15)
  colors.white = get_terminal_color(7) or get_hl_color("Gray", "fg") or "#d0d0d0"
  colors.bright_white = get_terminal_color(15) or get_hl_color("White", "fg") or "#ffffff"

  -- Ensure all colors are properly formatted
  for key, value in pairs(colors) do
    if type(value) == "string" and value:match("^#?%x+$") then
      colors[key] = ensure_hex(value)
    end
  end

  return colors
end

-- Export the current colorscheme to a Kitty theme file
function m.transform(path)
  -- Extract colors from current colorscheme
  local colors = extract_colors()

  -- Apply template
  local content = helpers.apply_template(template, colors)

  -- Create directory if it doesn't exist
  local dir = vim.fn.fnamemodify(path, ":h")
  vim.fn.mkdir(dir, "p")

  -- Check if file exists and ask for confirmation
  if vim.fn.filereadable(path) == 1 then
    local choice = vim.fn.confirm("File already exists: " .. path .. "\nOverwrite?", "&Yes\n&No", 2)
    if choice ~= 1 then
      print("Export cancelled")
      return
    end
  end

  -- Write the file
  local file = io.open(path, "w")
  if file then
    file:write(content)
    file:close()
    print("✓ Exported colorscheme to: " .. path)
  else
    error("Failed to write file: " .. path)
  end
end

return m
