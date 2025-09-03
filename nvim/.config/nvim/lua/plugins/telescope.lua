return {
  {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local builtin = require("telescope.builtin")
      vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = 'Find files' })
      vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = 'Search current word' })
      vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = 'Search by grep' })
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = 'Search diagnostics' })
      vim.keymap.set('n', '<leader>sb', builtin.buffers, { desc = 'Find existing buffers' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = 'Search keymaps' })
      vim.keymap.set('n', '<leader>sS', builtin.git_status, { desc = 'Search git status' })
    end,
    keys = {
      { '<leader>shf',
        function()
          require("telescope.builtin").find_files({ hidden = true })
        end,
        desc = 'Find files (hidden)' },
      { '<leader>shg',
        function()
          require("telescope.builtin").live_grep({
            additional_args = function(_)
              return { "--hidden", "--glob", "!.git/*" }
            end,
          })
        end,
        desc = 'Search grep (hidden)'
      },
      { '<leader>sf', function() require("telescope.builtin").find_files() end, desc = 'Find files' },
      { '<leader>sw', function() require("telescope.builtin").grep_string() end, desc = 'Search current word' },
      { '<leader>sg', function() require("telescope.builtin").live_grep() end, desc = 'Search by grep' },
      { '<leader>sd', function() require("telescope.builtin").diagnostics() end, desc = 'Search diagnostics' },
      { '<leader>sb', function() require("telescope.builtin").buffers() end, desc = 'Find existing buffers' },
      { '<leader>sk', function() require("telescope.builtin").keymaps() end, desc = 'Search keymaps' },
      { '<leader>sS', function() require("telescope.builtin").git_status() end, desc = 'Search git status' },
    }
  },
  -- for autocomplete telescope select
  {
    'nvim-telescope/telescope-ui-select.nvim',
    config = function()
      require("telescope").setup {
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown {
            }
          }
        },
        find_files = {
          hidden = true
        }
      }
      require("telescope").load_extension("ui-select")
    end
  },
}
