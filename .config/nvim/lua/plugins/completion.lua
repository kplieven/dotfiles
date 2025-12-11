local deps = require('mini.deps')

deps.add({
    source = 'saghen/blink.cmp',
    depends = {
        'rafamadriz/friendly-snippets',
        'fang2hou/blink-copilot'
    },
    checkout = 'v1.8.0',
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
