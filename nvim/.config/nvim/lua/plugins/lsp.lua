return {
  -- Mason helps with downloading and organising my LSPs
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end
  },
  -- Mason LSPconfig ensure smooth integration with nvim lspconfig
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",
          "kotlin_language_server",
          "hls",
          "pylsp",
          "clangd",
          -- "marksman"
        }
      })
    end
  },
  -- Enable Java lsp support
  {
    "mfussenegger/nvim-jdtls",
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
      -- lspconfig.jdtls.setup({
      --   capabilities = capabilities
      -- })
      lspconfig.pylsp.setup({
        capabilities = capabilities
      })
      lspconfig.clangd.setup({
        capabilities = capabilities
      })
      -- lspconfig.marksman.setup({
      --   capabilities = capabilities
      -- })


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
          -- vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
          -- vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, opts)
          -- vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, opts)
          -- vim.keymap.set('n', '<leader>wl', function()
          --   print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
          -- end, opts)
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
        float = false,
        severity_sort = true,
      })
      vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
        vim.lsp.diagnostic.on_publish_diagnostics, {
          -- delay update diagnostics
          update_in_insert = true,
        }
      )

      -- Diagnostics signs
      local signs = { Error = "󰚑", Warn = "󱍼", Hint = "󱘏", Info = "" }
      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
      end

      -- Print diagnostics in the message area
      -- function PrintDiagnostics(opts, bufnr, line_nr, client_id)
      --   bufnr = bufnr or 0
      --   line_nr = line_nr or (vim.api.nvim_win_get_cursor(0)[1] - 1)
      --   opts = opts or {['lnum'] = line_nr}
      --
      --   local line_diagnostics = vim.diagnostic.get(bufnr, opts)
      --   if vim.tbl_isempty(line_diagnostics) then return end
      --
      --   local diagnostic_message = ""
      --   for i, diagnostic in ipairs(line_diagnostics) do
      --     diagnostic_message = diagnostic_message .. string.format("%d: %s", i, diagnostic.message or "")
      --     print(diagnostic_message)
      --     if i ~= #line_diagnostics then
      --       diagnostic_message = diagnostic_message .. "\n"
      --     end
      --   end
      --   vim.api.nvim_echo({{diagnostic_message, "Normal"}}, false, {})
      -- end
      -- vim.cmd [[ autocmd! CursorHold * lua PrintDiagnostics() ]]
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
    opts = {

    },
    lazy = false,
    config = function()
      require("Comment").setup(
        {
          ---Add a space b/w comment and the line
          padding = true,
          ---Whether the cursor should stay at its position
          sticky = true,
          ---Lines to be ignored while (un)comment
          ignore = nil,
          ---LHS of toggle mappings in NORMAL mode
          toggler = {
            ---Line-comment toggle keymap
            line = 'gcc',
            ---Block-comment toggle keymap
            block = 'gbc',
          },
          ---LHS of operator-pending mappings in NORMAL and VISUAL mode
          opleader = {
            ---Line-comment keymap
            line = 'gc',
            ---Block-comment keymap
            block = 'gb',
          },
          ---LHS of extra mappings
          extra = {
            ---Add comment on the line above
            above = 'gcO',
            ---Add comment on the line below
            below = 'gco',
            ---Add comment at the end of line
            eol = 'gcA',
          },
          ---Enable keybindings
          ---NOTE: If given `false` then the plugin won't create any mappings
          mappings = {
            ---Operator-pending mapping; `gcc` `gbc` `gc[count]{motion}` `gb[count]{motion}`
            basic = true,
            ---Extra mapping; `gco`, `gcO`, `gcA`
            extra = true,
          },
          ---Function to call before (un)comment
          pre_hook = nil,
          ---Function to call after (un)comment
          post_hook = nil,
        }
      )
    end
  },
  
}
