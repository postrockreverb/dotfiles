local m = {}

function m.fraction(fraction)
  local total_cols = vim.o.columns
  local target = math.floor(total_cols * fraction)
  vim.cmd("vertical resize " .. target)
end

return m
