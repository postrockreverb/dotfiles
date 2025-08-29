local function indent(str, space)
  local lines = {}
  for line in str:gmatch("([^\n]*)\n?") do
    if line ~= "" then -- Prevent adding empty lines
      table.insert(lines, line)
    end
  end

  for i, line in ipairs(lines) do
    lines[i] = space .. line
  end

  return table.concat(lines, "\n")
end

local function tm_create(name, scopes)
  local template = [[
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>name</key>
  <string>%s</string>
  <key>settings</key>
  <array>
%s
  </array>
  <key>colorSpaceName</key>
  <string>sRGB</string>
</dict>
</plist>
]]

  return string.format(template, name, indent(scopes, "    "))
end

local function tm_settings(settings)
  local template = [[
<dict>
  <key>settings</key>
  <dict>
%s
  </dict>
</dict>
]]

  return string.format(template, indent(settings, "    "))
end

local function tm_scope(scope, settings)
  local template = [[
<dict>
  <key>name</key>
  <string>%s</string>
  <key>scope</key>
  <string>%s</string>
  <key>settings</key>
  <dict>
%s
  </dict>
</dict>
]]

  return string.format(template, scope, scope, indent(settings, "    "))
end

local function tm_entry(key, value)
  local template = [[
<key>%s</key>
<string>%s</string>
]]

  return string.format(template, key, value)
end

local function tm_hl_scope_settings(group)
  local settings = ""

  local hl = vim.api.nvim_get_hl_by_name(group, true)

  if hl.foreground then settings = settings .. tm_entry("foreground", string.format("#%06x", hl.foreground)) end

  if hl.background then settings = settings .. tm_entry("background", string.format("#%06x", hl.background)) end

  local font_styles = ""

  if hl.italic then font_styles = font_styles .. "italic" end

  if hl.bold then font_styles = font_styles .. "bold" end

  if font_styles then settings = settings .. tm_entry("fontStyle", font_styles) end

  return settings
end

local function hex(color)
  return string.format("#%06x", color or 0)
end

local m = {}

function m.transform(path)
  local colorscheme = vim.g.colors_name or "default"

  local settings = ""

  local cursor = vim.api.nvim_get_hl_by_name("Cursor", true)
  settings = settings .. tm_entry("caret", hex(cursor.foreground))

  local normal = vim.api.nvim_get_hl_by_name("Normal", true)
  settings = settings .. tm_entry("foreground", hex(normal.foreground))

  local whitespace = vim.api.nvim_get_hl_by_name("Whitespace", true)
  settings = settings .. tm_entry("invisibles", hex(whitespace.foreground))

  local cursorline = vim.api.nvim_get_hl_by_name("CursorLine", true)
  settings = settings .. tm_entry("lineHighlight", hex(cursorline.background))

  local visual = vim.api.nvim_get_hl_by_name("Visual", true)
  settings = settings .. tm_entry("selection", hex(visual.background))

  local linenr = vim.api.nvim_get_hl_by_name("LineNr", true)
  settings = settings .. tm_entry("gutterForeground", hex(linenr.foreground))

  local scopes = ""
  scopes = scopes .. tm_settings(settings)
  scopes = scopes .. tm_scope("entity.name.class", tm_hl_scope_settings("Type"))
  scopes = scopes .. tm_scope("entity.name.type", tm_hl_scope_settings("Type"))
  scopes = scopes .. tm_scope("entity.other.inherited-class", tm_hl_scope_settings("Type"))
  scopes = scopes .. tm_scope("entity.name.function", tm_hl_scope_settings("Function"))
  scopes = scopes .. tm_scope("entity.name.tag", tm_hl_scope_settings("Tag"))
  scopes = scopes .. tm_scope("entity.other.attribute-name", tm_hl_scope_settings("Identifier"))

  scopes = scopes .. tm_scope("variable", tm_hl_scope_settings("Identifier"))
  scopes = scopes .. tm_scope("variable.parameter", tm_hl_scope_settings("Identifier"))

  scopes = scopes .. tm_scope("constant.numeric", tm_hl_scope_settings("Number"))
  scopes = scopes .. tm_scope("constant.language", tm_hl_scope_settings("Constant"))
  scopes = scopes .. tm_scope("constant.character, constant.other", tm_hl_scope_settings("Constant"))

  scopes = scopes .. tm_scope("storage", tm_hl_scope_settings("Keyword"))
  scopes = scopes .. tm_scope("storage.type", tm_hl_scope_settings("Keyword"))

  scopes = scopes .. tm_scope("support.function", tm_hl_scope_settings("Function"))
  scopes = scopes .. tm_scope("support.constant", tm_hl_scope_settings("Constant"))
  scopes = scopes .. tm_scope("support.class", tm_hl_scope_settings("Special"))
  scopes = scopes .. tm_scope("support.type", tm_hl_scope_settings("Type"))
  scopes = scopes .. tm_scope("support.other.variable", tm_hl_scope_settings("Identifier"))

  scopes = scopes .. tm_scope("keyword", tm_hl_scope_settings("Keyword"))
  scopes = scopes .. tm_scope("punctuation, keyword.operator", tm_hl_scope_settings("Delimiter"))
  scopes = scopes .. tm_scope("keyword.operator.arithmetic", tm_hl_scope_settings("Statement"))

  scopes = scopes .. tm_scope("string, punctuation.definition.string", tm_hl_scope_settings("String"))

  scopes = scopes .. tm_scope("comment", tm_hl_scope_settings("Comment"))

  scopes = scopes .. tm_scope("invalid", tm_hl_scope_settings("Error"))
  scopes = scopes .. tm_scope("invalid.deprecated", tm_hl_scope_settings("DiagnosticDeprecated"))
  local content = tm_create(colorscheme, scopes)

  if io.open(path, "r") then
    local choice = vim.fn.confirm("Overwrite " .. path .. "?", "&Yes\n&No", 2)
    if choice == 2 then return end
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
