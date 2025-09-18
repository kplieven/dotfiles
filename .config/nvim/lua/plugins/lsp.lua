local deps = require('mini.deps')

deps.add('williamboman/mason.nvim')
deps.add('williamboman/mason-lspconfig.nvim')
deps.add('neovim/nvim-lspconfig')

require('mason').setup()
-- Setup mason-lspconfig with the NEW API
require('mason-lspconfig').setup({
    ensure_installed = { 'lua_ls', 'pyright', 'clangd', 'rust_analyzer' },
    handlers = {
        function(server_name)
            require('lspconfig')[server_name].setup({
                -- Blink.cmp handles capabilities automatically
            })
        end,
        ['lua_ls'] = function()
            require('lspconfig').lua_ls.setup({
                settings = {
                    Lua = {
                        diagnostics = {
                            globals = { 'vim' },
                        },
                    },
                },
            })
        end,
    }
})

vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(args)
        local opts = { buffer = args.buf }

        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, vim.tbl_extend('force', opts, { desc = 'Go to definition' }))
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, vim.tbl_extend('force', opts, { desc = 'Hover documentation' }))
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, vim.tbl_extend('force', opts, { desc = 'Rename symbol' }))
        vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action,
            vim.tbl_extend('force', opts, { desc = 'Code actions' }))
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, vim.tbl_extend('force', opts, { desc = 'Find references' }))
        vim.keymap.set('n', '<leader>lf', vim.lsp.buf.format, vim.tbl_extend('force', opts, { desc = 'Format buffer' }))

        -- Register LSP groups with which-key
        local wk = require('which-key')
        wk.add({
            { '<leader>c', group = 'Code',     buffer = args.buf },
            { '<leader>r', group = 'Refactor', buffer = args.buf },
        })
    end,
})
