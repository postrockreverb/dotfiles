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
vim.opt.expandtab = true

-- splits
vim.opt.splitbelow = true
vim.opt.splitright = true

-- not display a ~ for blank lines
vim.opt.fillchars:append("eob: ")

-- search
vim.opt.ignorecase = true
vim.opt.smartcase = true

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

-- spelling
vim.opt.spell = false

-- files
vim.opt.undofile = true
vim.opt.backup = false
vim.opt.swapfile = false

-- langmap
local function escape(str)
  local escape_chars = [[;,."|\]]
  return vim.fn.escape(str, escape_chars)
end

local en = [[`qwertyuiop[]asdfghjkl;'zxcvbnm]]
local ru = [[ёйцукенгшщзхъфывапролджэячсмить]]
local en_shift = [[~QWERTYUIOP{}ASDFGHJKL:"ZXCVBNM<>]]
local ru_shift = [[ËЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ]]

local langmap = vim.fn.join({
  escape(ru_shift) .. ";" .. escape(en_shift),
  escape(ru) .. ";" .. escape(en),
}, ",")

vim.opt.langmap = langmap

-- statusline
vim.o.statusline = "%f %h%w%m%r %{v:lua.diagnostics_status()}%=%-14.(%l,%c%V%) %P"

function _G.diagnostics_status()
  local result = {}

  local errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
  if errors > 0 then
    table.insert(result, "E:" .. errors)
  end

  local warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
  if warnings > 0 then
    table.insert(result, "W:" .. warnings)
  end

  local info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
  if info > 0 then
    table.insert(result, "I:" .. info)
  end

  local hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
  if hints > 0 then
    table.insert(result, "H:" .. hints)
  end

  return table.concat(result, " ")
end
