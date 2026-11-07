-- soft wrap at word boundaries
vim.opt_local.wrap = true
vim.opt_local.linebreak = true
vim.opt_local.breakindent = true
-- wrapped list items line up with the text after the bullet/number (uses 'formatlistpat'),
-- while plain paragraphs wrap flush left
vim.opt_local.breakindentopt = "list:-1"
-- also treat "> " quotes (and lists inside them) as markers, checked before the default patterns
vim.opt_local.formatlistpat = [[^\s*\(>\s*\)\+\([-*+]\s\+\|\d\+\.\s\+\)\?\|]] .. vim.bo.formatlistpat

-- move by screen line instead of real line
vim.keymap.set({ "n", "x" }, "j", "gj", { buffer = true })
vim.keymap.set({ "n", "x" }, "k", "gk", { buffer = true })
