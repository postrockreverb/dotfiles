-- Simple harpoon-like marks manager.
--
-- Reads marks from a `.nvim/harpoon` file at nvim cwd. Each line is either:
--   src/main.lua                -- file path (relative to cwd)
--   src/main.lua description    -- file path with description
--   src/main.lua:42             -- file path with line number
--   src/main.lua:42 description -- file path with line number and description
--
-- Empty lines and lines starting with # are ignored.

local m = {}

local function find_file(cwd)
  local path = cwd .. "/.nvim/harpoon"
  if vim.fn.filereadable(path) == 1 then
    return path
  end
  return nil
end

local function parse_line(line)
  line = vim.trim(line)
  if line == "" or line:match("^#") then
    return nil
  end

  local path, lnum, desc = line:match("^(%S+):(%d+)%s*(.*)$")
  local has_line = lnum ~= nil
  if not path then
    path, desc = line:match("^(%S+)%s*(.*)$")
  end

  return {
    path = path,
    line = tonumber(lnum) or 1,
    has_line = has_line,
    desc = desc ~= "" and desc or nil,
  }
end

m.list = function()
  local cwd = vim.fn.getcwd()
  local file_path = find_file(cwd)
  if not file_path then
    return {}
  end

  local lines = vim.fn.readfile(file_path)
  local marks = {}

  for _, line in ipairs(lines) do
    local mark = parse_line(line)
    if mark then
      table.insert(marks, mark)
    end
  end

  return marks
end

return m
