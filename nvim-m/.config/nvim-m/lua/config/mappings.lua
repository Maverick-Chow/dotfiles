-- map leader key
vim.g.mapleader = " "

-- split keymaps
vim.keymap.set("n", "<leader>wv", "<C-w>v", {desc = "Split window vertically"})
vim.keymap.set("n", "<leader>wh", "<C-w>s", {desc = "Split window horizontally"})
vim.keymap.set("n", "<leader>we", "<C-w>=", {desc = "Equalize window sizes"})
vim.keymap.set("n", "<leader>wx", ":close<CR>", {desc = "Close window"})
vim.keymap.set("n", "<leader>wm", ":MaximizerToggle<CR>", {desc = "Maximize window"})
