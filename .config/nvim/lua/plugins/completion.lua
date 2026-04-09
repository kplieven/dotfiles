vim.pack.add({
    { src = 'https://github.com/saghen/blink.cmp', version = vim.version.range('1') },
    'https://github.com/rafamadriz/friendly-snippets',
    'https://github.com/fang2hou/blink-copilot',
})

require('blink.cmp').setup({
    keymap = {
        preset = 'enter',
        ['<Tab>'] = { 'select_next', 'fallback' },
        ['<S-Tab>'] = { 'select_prev', 'fallback' },
    },
    sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer', 'copilot' },
        providers = {
            copilot = {
                name = 'copilot',
                module = 'blink-copilot',
                score_offset = 100,
                async = true,
            },
        },
    },
    completion = {
        documentation = {
            auto_show = true,
            auto_show_delay_ms = 120,
            window = {
                border       = 'rounded',
                max_width    = 80,
                max_height   = 20,
                winhighlight =
                'Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:BlinkCmpDocCursorLine',
            },
        },

        list = { selection = { preselect = true, auto_insert = false } },
        ghost_text = { enabled = true, show_with_menu = false },
    },
})
