return function(input_line_number, cursor_line)
    vim.o.termguicolors = false
    vim.o.laststatus = 0
    vim.o.cmdheight = 0
    vim.o.clipboard = "unnamedplus"

    local display_buf = vim.api.nvim_create_buf(false, true)
    local display_chan = vim.api.nvim_open_term(display_buf, {})

    vim.keymap.set("n", "q", "<Cmd>q<CR>", { buffer = display_buf, desc = "Quit pager" })

    local place_cursor = function()
        local total = vim.api.nvim_buf_line_count(display_buf)
        local target_line = math.min(input_line_number + cursor_line - 1, total)
        vim.cmd(string.format("normal! %dGzt", input_line_number))
        pcall(vim.api.nvim_win_set_cursor, 0, { target_line, 0 })
    end

    vim.api.nvim_create_autocmd("VimEnter", {
        once = true,
        callback = function(ev)
            local win = vim.api.nvim_get_current_win()
            local lines = vim.api.nvim_buf_get_lines(ev.buf, 0, -1, false)
            vim.api.nvim_chan_send(display_chan, table.concat(lines, "\r\n"))
            vim.api.nvim_win_set_buf(win, display_buf)
            vim.api.nvim_buf_delete(ev.buf, { force = true })
            vim.schedule(place_cursor)
        end,
    })
end
