return {
  -- Plugin name and repository
  "catppuccin/nvim",
  -- Plugin settings
  name = "catppuccin",
  priority = 1000,
  -- Plugin configuration
  config = function()
    vim.cmd.colorscheme "catppuccin"
  end
}


