if vim.env.TERM == "xterm-kitty" then
  local function set_kitty_mode(enabled)
    local seq = enabled
      and "\27]1337;SetUserVar=nvim_cmd=MQ==\7"
      or "\27]1337;SetUserVar=nvim_cmd\7"

    vim.api.nvim_ui_send(seq)
  end

  local function update_mode()
    local mode = vim.api.nvim_get_mode().mode
    -- Normal, Visual, Visual Line, Visual Block, Operator-pending
    local command_mode = mode:match("^[nvV\22]") ~= nil

    set_kitty_mode(command_mode)
  end

  vim.api.nvim_create_autocmd({
    "VimEnter",
    "UIEnter",
    "ModeChanged",
    "VimResume",
  }, {
    callback = update_mode,
  })

  vim.api.nvim_create_autocmd({
    "VimLeave",
    "VimSuspend",
  }, {
    callback = function()
      set_kitty_mode(false)
    end,
  })
end
