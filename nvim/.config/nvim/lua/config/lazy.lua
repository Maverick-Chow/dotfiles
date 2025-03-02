local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

if not vim.g.vscode then
  require("lazy").setup("plugins")
else
  require("lazy").setup({
    spec = {
      { import = "plugins.treesitter" },
      -- { import = "plugins.lsp"},
    },
  })
end
