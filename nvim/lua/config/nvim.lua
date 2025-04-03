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
vim.opt.smartindent = true

-- use number of spaces to insert a <Tab>
vim.opt.expandtab = true

-- not display a ~ for blank lines
vim.opt.fillchars:append("eob: ")

-- netrw settings
vim.g.netrw_plugin = 1
vim.g.netrw_banner = 0
vim.g.netrw_liststyle = 0
vim.g.netrw_fastbrowse = 2
vim.g.netrw_browse_split = 0
vim.g.netrw_list_hide = "^\\(\\.git\\|\\.DS_Store\\)"
vim.g.netrw_hide = 1
vim.g.netrw_localcopydircmd = "cp -r"
vim.g.netrw_localmkdir = "mkdir -p"
vim.g.netrw_localrmdir = "rm -r"

-- no line wrap
vim.wo.wrap = false

-- minimal number of screen lines to keep of the cursor
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8

-- highlight the current line
vim.opt.cursorline = false

-- folding
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevelstart = 99
vim.opt.foldtext = require("config.foldtext")

-- spelling
vim.opt.spell = false
