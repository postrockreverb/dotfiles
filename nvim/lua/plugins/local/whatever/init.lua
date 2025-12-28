local function make_fixed_width_banner(text)
  local width = 72

  local prefix = "// "
  local inner_width = width - #prefix
  if inner_width < 1 then
    return prefix .. text
  end

  local core = (" %s "):format(text) -- spaces around text
  if #core > inner_width then
    -- too long to fit nicely; don't force it
    return prefix .. text
  end

  local dash_total = inner_width - #core
  local left = math.floor(dash_total / 2)
  local right = dash_total - left

  return prefix .. string.rep("-", left) .. core .. string.rep("-", right)
end

local m = {}

m.insert = function()
  vim.ui.input({ prompt = "Prompt: " }, function(input)
    if input == nil or input == "" then
      return
    end

    local banner = make_fixed_width_banner(input)

    local row = vim.api.nvim_win_get_cursor(0)[1] -- 1-based
    local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ""

    if line:match("^%s*$") then
      -- current line empty -> replace it
      vim.api.nvim_buf_set_lines(0, row - 1, row, false, { banner })
    else
      -- otherwise insert above
      vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, { banner })
    end
  end)
end

return m
