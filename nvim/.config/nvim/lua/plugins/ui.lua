return {
  {
    -- Plugin name and repository
    "catppuccin/nvim",
    -- Plugin settings
    name = "catppuccin",
    priority = 1000,
    -- Plugin configuration
    config = function()
      vim.cmd.colorscheme "catppuccin"
    end
  },
  {
    "nvim-lualine/lualine.nvim",
    config = function()
      require('lualine').setup({
        option = {
          -- theme = 'dracula'
          theme = 'ayu_light'
        }
      })
    end
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    config = function()
      vim.keymap.set('n', '<C-t>', ':Neotree toggle float<CR>')
    end
  },
  {
    "Isrothy/neominimap.nvim",
    version = "v3.*.*",
    enabled = true,
    lazy = false, -- NOTE: NO NEED to Lazy load
    -- Optional
    keys = {
      -- Window-Specific Minimap Controls
      { "<leader>mm", "<cmd>Neominimap winToggle<cr>",   desc = "Toggle minimap for current window" },
      { "<leader>mo", "<cmd>Neominimap winRefresh<cr>",  desc = "Refresh minimap for current window" },
      { "<leader>mf", "<cmd>Neominimap toggleFocus<cr>", desc = "Switch focus on minimap" },
    },
    init = function()
      -- The following options are recommended when layout == "float"
      vim.opt.wrap = false
      vim.opt.sidescrolloff = 36 -- Set a large value

      --- Put your configuration here
      vim.g.neominimap = {
        auto_enable = false,
      }
    end,
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "helix",
      spec = {
        { "<leader>g", group = "Git" },   -- group
        { "<leader>m", group = "Minimap" },
        { "<leader>a", group = "Avante" },
        { "<leader>s", group = "Search and Find" },
        { "<leader>u", group = "Toggles" },
        { "<leader>w", group = "Window management" },
        { "[", group = "Previous ..." },
      }
    },
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Buffer Local Keymaps (which-key)",
      },
    },
  }
}
