--- Replace $values in a string from a table of {values = "string"}
-- "my_color is $COLOR", {COLOR = "red"} -> "my_color is red"
-- @param template A string
-- @param map A table of replacement values
local function apply_template(template, map)
  -- ensure that each replacement value is a string
  local stringable = function(check)
    if type(check) == "table" then
      -- tables *might* be tostring-able
      local maybe_tostring = rawget(getmetatable(check) or {}, "__tostring")
      return type(maybe_tostring) == "function"
    elseif type(check) == "function" then
      -- functions are never tostring-able
      return false
    else
      -- assume other types have runtime tostring functions
      return true
    end
  end

  local replacements = {}
  for key, val in pairs(map) do
    assert(stringable(val), "template value could not convert to string for key: " .. key .. " got: " .. type(val))
    replacements[key] = tostring(val)
  end

  return string.gsub(template, "$([%w%d_]+)", replacements)
end

--- Converts a mutli-line string into a table of lines
-- @param text The multi-line string
local function split_newlines(text)
  local lines = {}
  for s in string.gmatch(text, "[^\n]+") do
    table.insert(lines, s)
  end

  return lines
end

return {
  -- split string into table by new lines
  split_newlines = split_newlines,
  -- apply "this is my $template", {template = "replacement"} templating
  apply_template = apply_template,
}
