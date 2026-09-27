local M = {}

-- `ensure_installed = false` opts a tool out of Mason, for tools Mason has no
-- package for (Godot ships its own gdscript LSP and we only connect to it).
M.ensure_installed = function()
  local servers = require("tools.servers")
  local linters = require("tools.linters")
  local formatters = require("tools.formatters")

  local map = {}
  for _, group in ipairs({ servers, formatters, linters }) do
    for name, spec in pairs(group) do
      if spec.ensure_installed ~= false then
        table.insert(map, name)
      end
    end
  end
  return map
end

-- The specs double as vim.lsp.config tables, so each one is copied without
-- `ensure_installed`: that key is ours, not the server's. Copies also keep
-- callers from merging their capabilities into the module's own tables.
M.servers = function()
  local map = {}
  for name, spec in pairs(require("tools.servers")) do
    local cfg = vim.tbl_extend("force", {}, spec)
    cfg.ensure_installed = nil
    map[name] = cfg
  end
  return map
end

M.formatters_by_ft = function()
  local formatters = require("tools.formatters")

  local map = {}
  for name, spec in pairs(formatters) do
    for _, ft in ipairs(spec.filetypes) do
      map[ft] = map[ft] or {}
      table.insert(map[ft], name)
    end
  end
  return map
end

M.formatters_settings = function()
  local formatters = require("tools.formatters")

  local map = {}
  for name, spec in pairs(formatters) do
    map[name] = spec.settings or {}
  end
  return map
end

M.linters_by_ft = function()
  local linters = require("tools.linters")

  local map = {}
  for name, spec in pairs(linters) do
    for _, ft in ipairs(spec.filetypes) do
      map[ft] = map[ft] or {}
      table.insert(map[ft], name)
    end
  end
  return map
end

return M
