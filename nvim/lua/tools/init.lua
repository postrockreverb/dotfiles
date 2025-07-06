local formatters = require("tools.formatters")
local linters = require("tools.linters")
local servers = require("tools.servers")

local M = {}

M.servers = servers
M.formatters = formatters
M.linters = linters

M.ensure_installed = (function()
  local map = {}
  vim.list_extend(map, vim.tbl_keys(servers))
  vim.list_extend(map, vim.tbl_keys(formatters))
  vim.list_extend(map, vim.tbl_keys(linters))
  return map
end)()

M.formatters_by_ft = (function()
  local map = {}
  for name, spec in pairs(formatters) do
    for _, ft in ipairs(spec.filetypes) do
      map[ft] = map[ft] or {}
      table.insert(map[ft], name)
    end
  end
  return map
end)()

M.formatters_settings = (function()
  local map = {}
  for name, spec in pairs(formatters) do
    map[name] = spec.settings or {}
  end
  return map
end)()

M.linters_by_ft = (function()
  local map = {}
  for name, spec in pairs(linters) do
    for _, ft in ipairs(spec.filetypes) do
      map[ft] = map[ft] or {}
      table.insert(map[ft], name)
    end
  end
  return map
end)()

return M
