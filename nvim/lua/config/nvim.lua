-- leader
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- clipboard
vim.opt.clipboard = "unnamedplus"

-- enable line number and relative line number
vim.opt.number = true
vim.opt.relativenumber = true

-- width of a tab
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.softtabstop = 2

-- use number of spaces to insert a <Tab>
vim.opt.expandtab = true

-- not display a ~ for blank lines
vim.opt.fillchars:append("eob: ")

-- disable netrw
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_netrw = 1

-- no line wrap
vim.wo.wrap = false

-- minimal number of screen lines to keep of the cursor
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8

-- highlight the current line
vim.opt.cursorline = false

-- folding
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldlevel = 99
