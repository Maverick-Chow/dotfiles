-- soft wrap at word boundaries
vim.opt_local.wrap = true
vim.opt_local.linebreak = true
vim.opt_local.breakindent = true
vim.opt_local.showbreak = "↪ "

-- move by screen line instead of real line
vim.keymap.set({ "n", "x" }, "j", "gj", { buffer = true })
vim.keymap.set({ "n", "x" }, "k", "gk", { buffer = true })
