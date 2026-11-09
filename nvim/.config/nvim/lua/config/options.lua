vim.lsp.set_log_level("debug")
-- enable line number and relative line number
vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.colorcolumn = '80'

-- width of a tab
vim.opt.shiftwidth =  2
vim.opt.tabstop =     2
vim.opt.softtabstop = 2

vim.opt.autoindent = true
vim.opt.smartindent = true

vim.opt.scrolloff = 8

-- yank to clipboard
vim.opt.clipboard = 'unnamedplus'

-- Headless Linux (no X/Wayland): copy through OSC 52 so yanks reach the client
-- terminal. Paste from nvim's own registers, since many terminals block OSC 52 reads.
if vim.fn.has("mac") == 0 and not os.getenv("DISPLAY") and not os.getenv("WAYLAND_DISPLAY") then
  local osc52 = require("vim.ui.clipboard.osc52")
  local function paste()
    return { vim.split(vim.fn.getreg('"'), "\n"), vim.fn.getregtype('"') }
  end
  vim.g.clipboard = {
    name = "OSC 52",
    copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
    paste = { ["+"] = paste, ["*"] = paste },
  }
end

-- use number of spaces to insert a <Tab>
vim.opt.expandtab = true

vim.opt.conceallevel = 2
vim.opt.signcolumn = 'yes'
