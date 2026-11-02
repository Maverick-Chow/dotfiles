return {
  {
    "rose-pine/neovim",
    name = "rose-pine",
    priority = 1000,
    config = function()
      require("rose-pine").setup({ dark_variant = "moon" })
      -- default until auto-dark-mode picks moon/dawn from the system appearance
      vim.cmd.colorscheme "rose-pine-moon"
    end,
  },
  {
    -- follow macOS appearance: rose pine moon (dark) / rose pine dawn (light)
    "f-person/auto-dark-mode.nvim",
    lazy = false,
    opts = {
      set_dark_mode = function()
        vim.o.background = "dark"
        vim.cmd.colorscheme "rose-pine-moon"
      end,
      set_light_mode = function()
        vim.o.background = "light"
        vim.cmd.colorscheme "rose-pine-dawn"
      end,
      update_interval = 3000,
      fallback = "dark",
    },
  },
  {
    "j-hui/fidget.nvim",
    opts = {},
  },
  {
    "nvim-lualine/lualine.nvim",
    config = function()
      -- theme defaults to "auto", which follows the active colorscheme
      require('lualine').setup({})
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
      require('neominimap').on()
      require('neominimap').winOff({})
      vim.api.nvim_create_autocmd({"WinNew"}, {
        callback = function()
          require('neominimap').winOff({})
        end,
      })
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
