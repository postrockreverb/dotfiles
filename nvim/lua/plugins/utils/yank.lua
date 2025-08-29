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

return m
