local m = {}

function m.clear_hidden()
  for _, buffer in pairs(vim.fn.getbufinfo()) do
    if buffer.hidden == 1 then
      vim.cmd.bd(buffer.bufnr)
    end
  end
end

return m
