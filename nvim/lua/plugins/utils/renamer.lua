local M = {}

function M.rename_insert()
  local new_name = vim.fn.input("Rename: ")
  if new_name == "" then
    return
  end

  vim.lsp.buf.rename(new_name)
end

function M.rename_append()
  local current_word = vim.fn.expand("<cword>")

  local new_name = vim.fn.input("Rename: ", current_word)
  if new_name == "" then
    return
  end

  vim.lsp.buf.rename(new_name)
end

return M
