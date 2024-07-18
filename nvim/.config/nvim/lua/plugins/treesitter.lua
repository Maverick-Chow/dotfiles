return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local config = require("nvim-treesitter.configs")
    config.setup({
      highlight = { enable = true },
      indent = { enable = true },
      ensure_installed = {
        "lua",
        "haskell",
        "c",
        "css",
        "dockerfile",
        "git_config",
        "git_rebase",
        "gitignore",
        "html",
        "kotlin",
        "java",
        "markdown",
        "markdown_inline",
        "sql",
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          scope_incremental = false,
          node_decremental = "<bs>",
        }
      },
    })
  end
}
