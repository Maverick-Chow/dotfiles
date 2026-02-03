return {
  -- Mason helps with downloading and organising my LSPs
  {
    "mason-org/mason.nvim",
    opts = {}
  },
  -- Mason LSPconfig ensure smooth integration with nvim lspconfig
  {
    "williamboman/mason-lspconfig.nvim",
    opts = {
      ensure_installed = {
        "lua_ls",
        "kotlin_language_server",
        "hls",
        "pylsp",
        "clangd",
        "cmake",
        "ts_ls",
      }
    },
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      "neovim/nvim-lspconfig",
    }
  },
  -- Enable lsp support in nvim
  {
    "neovim/nvim-lspconfig",
    config = function()
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      local lspconfig = require("lspconfig")
      lspconfig.lua_ls.setup({
        capabilities = capabilities
      })
      lspconfig.hls.setup({
        capabilities = capabilities
      })
      lspconfig.pylsp.setup({
        capabilities = capabilities
      })
      lspconfig.clangd.setup({
        capabilities = capabilities
      })
      lspconfig.cmake.setup({
        capabilities = capabilities
      })
      lspconfig.ts_ls.setup({
        capabilities = capabilities
      })


      -- Global mappings.
      -- See `:help vim.diagnostic.*` for documentation on any of the below functions
      vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open diagnostic float' })
      vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Previous diagnostic' })
      vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Next diagnostic' })

      -- Use LspAttach autocommand to only map the following keys
      -- after the language server attaches to the current buffer
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('UserLspConfig', {}),
        callback = function(ev)
          -- Enable completion triggered by <c-x><c-o>
          vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

          -- Buffer local mappings.
          -- See `:help vim.lsp.*` for documentation on any of the below functions
          local opts = { buffer = ev.buf }
          vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, { desc = 'Go to declaration', buffer = opts.buffer })
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = 'Go to definition', buffer = opts.buffer })
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, { desc = 'Show hover', buffer = opts.buffer })
          vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, { desc = 'Go to implementation', buffer = opts.buffer })
          vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition, { desc = 'Show type definition', buffer = opts.buffer })
          vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { desc = 'Rename', buffer = opts.buffer })
          vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, { desc = 'Code action', buffer = opts.buffer })
          vim.keymap.set('n', 'gr', vim.lsp.buf.references, { desc = 'Go to references', buffer = opts.buffer })
          vim.keymap.set('n', '<leader>f', function()
            vim.lsp.buf.format { async = true }
          end, { desc = 'Format', buffer = opts.buffer })
        end,
      })

      -- Diagnostics config
      vim.diagnostic.config({
        virtual_text = false,
        underline = true,
        signs = true,
        float = true,
        severity_sort = true,
      })

      -- Diagnostics signs
      local signs = { Error = "E", Warn = "W", Hint = "H", Info = "I" }
      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
      end
    end
  },
  -- Cmp nvim lsp integrates nvim cmp with lsp config
  {
    "hrsh7th/cmp-nvim-lsp"
  },
  -- Nvim cmp enables auto completion in nvim
  {
    "hrsh7th/nvim-cmp",
    config = function()
      local cmp = require 'cmp'

      cmp.setup({
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
          ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<Tab>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
        }, {
          { name = 'buffer' },
        })
      })
    end
  },
  -- Comment.nvim enables commenting and uncommenting code
  {
    "numToStr/Comment.nvim",
  },
  {
      'Kicamon/markdown-table-mode.nvim',
      config = function()
          require('markdown-table-mode').setup()
      end
  },
}
