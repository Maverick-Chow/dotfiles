vim.lsp.set_log_level("debug")
-- enable line number and relative line number
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.colorcolumn = '80'

-- width of a tab
vim.opt.shiftwidth =  2
vim.opt.tabstop =     2
vim.opt.softtabstop = 2

vim.opt.autoindent = true
vim.opt.smartindent = true

-- yank to clipboard
vim.opt.clipboard = 'unnamedplus'

-- use number of spaces to insert a <Tab>
vim.opt.expandtab = true

vim.opt.conceallevel = 2
