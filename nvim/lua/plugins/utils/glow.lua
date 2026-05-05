local m = {}

function m.preview()
  local file = vim.fn.expand("%:p")
  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
  })
  vim.fn.jobstart("glow " .. vim.fn.shellescape(file), { term = true })
  local function close()
    vim.api.nvim_win_close(win, true)
    vim.api.nvim_buf_delete(buf, { force = true })
  end
  vim.keymap.set({ "t", "n" }, "<Esc>", close, { buffer = buf })
end

return m
