local function find(pattern, filename)
  local command = string.format('find %s -type f -name "%s.*" 2>/dev/null', pattern, filename)

  local handle = io.popen(command)
  if not handle then
    return {}
  end

  local result = handle:read("*a")
  handle:close()

  local files = {}
  for file in result:gmatch("[^\r\n]+") do
    table.insert(files, file)
  end

  return files
end

local function read_snippet(snippet, key)
  local prefix = snippet.prefix or key
  local description = snippet.description or key

  local body = snippet.body
  if type(snippet.body) == "table" then
    body = table.concat(snippet.body, "\n")
  end

  local prefixes = { prefix }
  if type(prefix) == "table" then
    prefixes = prefix
  end

  local snippets = {}
  for _, p in ipairs(prefixes) do
    ---@type lsp.CompletionItem
    snippets[#snippets + 1] = {
      word = p,
      label = p,
      insertText = body,
      description = description,
      kind = vim.lsp.protocol.CompletionItemKind.Snippet,
      insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
    }
  end

  return snippets
end

local function scan_file(path)
  local file = io.open(path, "r")
  if not file then
    return {}
  end

  local content = file:read("*a")
  file:close()
  if content == "" then
    return {}
  end

  local success, snippets = pcall(function()
    return vim.json.decode(content)
  end)

  if not success then
    return {}
  end

  local result = {}

  for _, key in ipairs(vim.tbl_keys(snippets)) do
    local snippet = read_snippet(snippets[key], key)
    vim.list_extend(result, snippet)
  end

  return result
end

local function scan_paths(search_paths, filename)
  local files = {}
  for _, path in ipairs(search_paths) do
    local path_files = find(path, filename)
    vim.list_extend(files, path_files)
  end

  local result = {}
  for _, file in ipairs(files) do
    local snippets = scan_file(file)
    if next(snippets) == nil then
      goto continue
    end

    vim.list_extend(result, snippets)
    ::continue::
  end

  return result
end

M = {}
function M.source(search_paths)
  if not search_paths then
    return {}
  end

  local cache = {}

  local cmp_source = {}
  function cmp_source.complete(_, _, callback)
    local bufnr = vim.api.nvim_get_current_buf()
    if not cache[bufnr] then
      cache[bufnr] = scan_paths(search_paths, vim.bo.filetype)
    end
    callback(cache[bufnr])
  end

  return cmp_source
end

return M
