vim.pack.add({
    'https://github.com/williamboman/mason.nvim',
    'https://github.com/williamboman/mason-lspconfig.nvim',
    'https://github.com/neovim/nvim-lspconfig',
})

-- Per-server overrides. These deep-merge on top of the defaults nvim-lspconfig
-- ships in its `lsp/` directory, so only the differences belong here.
-- Blink.cmp contributes capabilities globally via vim.lsp.config('*').
vim.lsp.config('lua_ls', {
    settings = {
        Lua = {
            diagnostics = {
                globals = { 'vim' },
            },
        },
    },
})

require('mason').setup()
-- mason-lspconfig v2 calls vim.lsp.enable() for every installed server itself;
-- there is no `handlers` option any more.
require('mason-lspconfig').setup({
    ensure_installed = {
        'lua_ls',
        'pyright',
        'clangd',
        'rust_analyzer',
        'docker_language_server',
    },
})

vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(args)
        local opts = { buffer = args.buf }

        vim.keymap.set('n', 'gd', function()
            require('fzf-lua').lsp_definitions()
        end, vim.tbl_extend('force', opts, { desc = 'Go to definition (fzf)' }))
        vim.keymap.set('n', 'gt', vim.lsp.buf.type_definition, vim.tbl_extend('force', opts, { desc = 'Go to type definition' }))
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, vim.tbl_extend('force', opts, { desc = 'Hover documentation' }))
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, vim.tbl_extend('force', opts, { desc = 'Rename symbol' }))
        vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action,
            vim.tbl_extend('force', opts, { desc = 'Code actions' }))
        vim.keymap.set('n', 'gr', function()
            require('fzf-lua').lsp_references()
        end, vim.tbl_extend('force', opts, { desc = 'Find references (fzf)' }))
        vim.keymap.set('n', '<leader>lf', vim.lsp.buf.format, vim.tbl_extend('force', opts, { desc = 'Format buffer' }))

        -- Register LSP groups with which-key
        local wk = require('which-key')
        wk.add({
            { '<leader>c', group = 'Code',     buffer = args.buf },
            { '<leader>r', group = 'Refactor', buffer = args.buf },
        })
    end,
})
