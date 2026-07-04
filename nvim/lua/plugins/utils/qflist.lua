local m = {}

function m.add_current_line()
  vim.fn.setqflist({
    {
      bufnr = vim.api.nvim_get_current_buf(),
      lnum = vim.fn.line("."),
      col = vim.fn.col("."),
      text = vim.api.nvim_get_current_line(),
    },
  }, "a")
end

function m.clear()
  vim.fn.setqflist({}, "r")
end

return m
