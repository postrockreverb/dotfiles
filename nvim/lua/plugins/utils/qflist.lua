local m = {}

function m.toggle_current_line()
  local bufnr = vim.api.nvim_get_current_buf()
  local lnum = vim.fn.line(".")

  local items = vim.fn.getqflist()
  for i, item in ipairs(items) do
    if item.bufnr == bufnr and item.lnum == lnum then
      table.remove(items, i)
      vim.fn.setqflist(items, "r")
      return
    end
  end

  vim.fn.setqflist({
    {
      bufnr = bufnr,
      lnum = lnum,
      col = vim.fn.col("."),
      text = vim.api.nvim_get_current_line(),
    },
  }, "a")
end

function m.clear()
  vim.fn.setqflist({}, "r") --
end

return m
