local m = {}

function m.path()
  local path = vim.api.nvim_buf_get_name(0)
  path = vim.fn.fnamemodify(path, ":.")
  vim.fn.setreg("+", path)
end

function m.pathlinenr()
  local path = vim.api.nvim_buf_get_name(0)
  path = vim.fn.fnamemodify(path, ":.")
  local linenr = vim.api.nvim_win_get_cursor(0)[1]
  vim.fn.setreg("+", path .. ":" .. linenr)
end

--
-- qualified symbol name: container path + symbol, e.g.
-- "github.com/acme/proj/pkg/statefile.State" — meant for pasting into an llm
--
-- built from plain lsp requests, so nothing here is language specific:
--   1. textDocument/definition           -> where the symbol is declared
--   2. workspace/symbol                  -> container + name for workspace symbols
--   3. prepareTypeHierarchy / CallHierarchy -> same for deps and stdlib
--

local function yank(name)
  vim.fn.setreg("+", name)
end

-- definition may come back as Location, Location[] or LocationLink[]
local function first_location(result)
  if not result then
    return nil
  end
  local loc = result.uri and result or result[1]
  if not loc then
    return nil
  end
  return {
    uri = loc.uri or loc.targetUri,
    range = loc.range or loc.targetSelectionRange or loc.targetRange,
  }
end

-- gopls encodes call hierarchy detail as "pkg/path • file.go"
local function container_of(detail)
  if not detail or detail == "" then
    return nil
  end
  return vim.split(detail, " • ", { plain = true })[1]
end

local function compose(container, name)
  if not container or container == "" or name:sub(1, #container) == container then
    return name
  end
  local separator = container:find("::", 1, true) and "::" or "."
  return container .. separator .. name
end

local function match_symbol(symbols, loc, word)
  for _, symbol in ipairs(symbols or {}) do
    local location = symbol.location
    if location and location.uri == loc.uri then
      -- WorkspaceSymbol may carry a uri without a range
      if not location.range or not loc.range then
        if symbol.name:sub(-#word) == word then
          return symbol
        end
      elseif location.range.start.line == loc.range.start.line then
        return symbol
      end
    end
  end
  return nil
end

-- hierarchy items drop the receiver ("Context"), documentSymbol keeps it ("(*common).Context")
local function refine(client, bufnr, item, callback)
  if not client:supports_method("textDocument/documentSymbol", bufnr) then
    return callback(item.name)
  end

  local line = (item.selectionRange or item.range).start.line
  client:request("textDocument/documentSymbol", { textDocument = { uri = item.uri } }, function(_, symbols)
    local name = item.name

    local function walk(list)
      for _, symbol in ipairs(list or {}) do
        local range = symbol.selectionRange or symbol.range or (symbol.location and symbol.location.range)
        local qualifies = #symbol.name > #name and symbol.name:find(item.name, 1, true)
        if range and range.start.line == line and qualifies then
          name = symbol.name
        end
        walk(symbol.children)
      end
    end

    walk(symbols)
    callback(name)
  end, bufnr)
end

local function from_hierarchy(client, params, bufnr, methods)
  local method = table.remove(methods, 1)
  if not method then
    vim.notify("No qualified name for symbol", vim.log.levels.WARN, { title = "Yank" })
    return
  end

  if not client:supports_method(method, bufnr) then
    return from_hierarchy(client, params, bufnr, methods)
  end

  client:request(method, params, function(_, result)
    local item = result and result[1]
    if not item then
      return from_hierarchy(client, params, bufnr, methods)
    end
    refine(client, bufnr, item, function(name) yank(compose(container_of(item.detail), name)) end)
  end, bufnr)
end

function m.qualified()
  local bufnr = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()
  local word = vim.fn.expand("<cword>")

  local client = vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/definition" })[1]
  if not client then
    vim.notify("No lsp client for buffer", vim.log.levels.WARN, { title = "Yank" })
    return
  end

  local params = vim.lsp.util.make_position_params(win, client.offset_encoding)
  local hierarchy = { "textDocument/prepareTypeHierarchy", "textDocument/prepareCallHierarchy" }

  client:request("textDocument/definition", params, function(_, result)
    local loc = first_location(result)
    if not loc or not client:supports_method("workspace/symbol", bufnr) then
      return from_hierarchy(client, params, bufnr, hierarchy)
    end

    client:request("workspace/symbol", { query = word }, function(_, symbols)
      local symbol = match_symbol(symbols, loc, word)
      if not symbol then
        return from_hierarchy(client, params, bufnr, hierarchy)
      end
      yank(compose(symbol.containerName, symbol.name))
    end, bufnr)
  end, bufnr)
end

return m
