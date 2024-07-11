return {
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end
  },
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",
          "kotlin_language_server",
          -- "hls",
          "jdtls",
          "pylsp",
          "clangd",
        }
      })
    end
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      local lspconfig = require("lspconfig")
      lspconfig.lua_ls.setup({
        capabilities = capabilities
      })
      lspconfig.kotlin_language_server.setup({
        capabilities = capabilities
      })
      -- lspconfig.hls.setup({
      --   capabilities = capabilities
      -- })
      lspconfig.jdtls.setup({
        capabilities = capabilities
      })
      lspconfig.pylsp.setup({
        capabilities = capabilities
      })
      lspconfig.clangd.setup({
        capabilities = capabilities
      })


      -- Global mappings.
      -- See `:help vim.diagnostic.*` for documentation on any of the below functions
      vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float)
      vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
      vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
      vim.keymap.set('n', '<leader>q', '<cmd>Telescope diagnostics<CR>')

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
          vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
          vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
          vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
          vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, opts)
          vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, opts)
          vim.keymap.set('n', '<leader>wl', function()
            print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
          end, opts)
          vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition, opts)
          vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
          vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, opts)
          vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
          vim.keymap.set('n', '<leader>f', function()
            vim.lsp.buf.format { async = true }
          end, opts)
        end,
      })

      -- Diagnostics config
      vim.diagnostic.config({
        virtual_text = false,
        underline = true,
        update_in_insert = false,
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
  }
}
