local helpers = require("plugins.local.export-theme.helpers")

-- NB: Lines with "$" in them are stripped from the final output, this
--     allows the transform user to not have to specify everything.
-- https://raw.githubusercontent.com/kovidgoyal/kitty-themes/master/template.conf
local template = [[
# vim:ft=kitty
# This is a template that can be used to create new kitty themes$
# Theme files should start with a metadata block consisting of$
# lines beginning with ##. All metadata fields are optional.$

## name: $name
## author: $author
## license: $license
## upstream: $upstream
## blurb: $blurb

# All the settings below are colors, which you can choose to modify, or use the$
# defaults. You can also add non-color based settings if needed but note that$
# these will not work with using kitty @ set-colors with this theme. For a reference$
# on what these settings do see https://sw.kovidgoyal.net/kitty/conf/$

# The basic colors$
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
wayland_titlebar_color $titlebar
macos_titlebar_color $titlebar

# Tab bar colors
active_tab_foreground           $tab_active_fg
active_tab_background           $tab_active_bg
inactive_tab_foreground         $tab_inactive_fg
inactive_tab_background         $tab_inactive_bg
tab_bar_background              $tab_bg

# Colors for marks (marked text in the terminal)

mark1_foreground $mark1_fg
mark1_background $mark1_bg
mark2_foreground $mark2_fg
mark2_background $mark2_bg
mark3_foreground $mark3_fg
mark3_background $mark3_bg

# The basic 16 colors
# black
color0 $black
color8 $bright_black

# red
color1 $red
color9 $bright_red

# green
color2  $green
color10 $bright_green

# yellow
color3  $yellow
color11 $bright_yellow

# blue
color4  $blue
color12 $bright_blue

# magenta
color5  $magenta
color13 $bright_magenta

# cyan
color6  $cyan
color14 $bright_cyan

# white
color7  $white
color15 $bright_white

# You can set the remaining 240 colors as color16 to color255.]]

local check_keys = {
  "fg",
  "bg",
  "cursor_fg",
  "cursor_bg",
  "selection_fg",
  "selection_bg",
  "black",
  "red",
  "green",
  "yellow",
  "blue",
  "magenta",
  "cyan",
  "white",
  "bright_black",
  "bright_red",
  "bright_green",
  "bright_yellow",
  "bright_blue",
  "bright_magenta",
  "bright_cyan",
  "bright_white",
}

local function color(group, attr)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group })
  if ok and hl[attr] then return string.format("#%06X", hl[attr]) end
  return "#000000" -- fallback
end

local m = {}

function m.transform(path)
  local colorscheme = vim.g.colors_name or "default"

  local colors = {
    fg = color("Normal", "fg"),
    bg = color("Normal", "bg"),
    cursor_fg = color("Cursor", "fg"),
    cursor_bg = color("Cursor", "bg"),
    selection_fg = color("Visual", "fg"),
    selection_bg = color("Visual", "bg"),

    black = color("Black", "fg"),
    red = color("Red", "fg"),
    green = color("Green", "fg"),
    yellow = color("Yellow", "fg"),
    blue = color("Blue", "fg"),
    magenta = color("Magenta", "fg"),
    cyan = color("Cyan", "fg"),
    white = color("White", "fg"),

    bright_black = color("BrightBlack", "fg"),
    bright_red = color("BrightRed", "fg"),
    bright_green = color("BrightGreen", "fg"),
    bright_yellow = color("BrightYellow", "fg"),
    bright_blue = color("BrightBlue", "fg"),
    bright_magenta = color("BrightMagenta", "fg"),
    bright_cyan = color("BrightCyan", "fg"),
    bright_white = color("BrightWhite", "fg"),

    -- optional fields (fallbacks or reuse)
    url = color("Underlined", "fg"),
    border_active = color("FloatBorder", "fg"),
    border_inactive = color("WinSeparator", "fg"),
    border_bell = color("WarningMsg", "fg"),
    titlebar = color("Title", "fg"),

    tab_active_fg = color("TabLineSel", "fg"),
    tab_active_bg = color("TabLineSel", "bg"),
    tab_inactive_fg = color("TabLine", "fg"),
    tab_inactive_bg = color("TabLine", "bg"),
    tab_bg = color("TabLineFill", "bg"),

    mark1_fg = color("DiffAdd", "fg"),
    mark1_bg = color("DiffAdd", "bg"),
    mark2_fg = color("DiffChange", "fg"),
    mark2_bg = color("DiffChange", "bg"),
    mark3_fg = color("DiffDelete", "fg"),
    mark3_bg = color("DiffDelete", "bg"),

    name = colorscheme,
    author = "Auto-generated",
    license = "MIT",
    upstream = "N/A",
    blurb = "Theme auto-converted from " .. colorscheme .. " Neovim colorscheme",
  }

  for _, key in ipairs(check_keys) do
    assert(colors[key], "kitty colors table missing required key: " .. key)
  end

  local replaced = helpers.split_newlines(helpers.apply_template(template, colors))

  local content = ""
  for _, line in ipairs(replaced) do
    if not string.match(line, "%$") then content = content .. line .. "\n" end
  end

  if io.open(path, "r") then
    local choice = vim.fn.confirm("Overwrite " .. path .. "?", "&Yes\n&No", 2)
    if choice == 2 then return end
  end

  local file = io.open(path, "w")
  if file then
    file:write(content)
    file:close()
    print("Colorscheme converted to kitty: " .. path)
  else
    print("Failed to write kitty file.")
  end
end

return m
