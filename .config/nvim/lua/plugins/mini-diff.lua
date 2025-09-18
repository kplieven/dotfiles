local deps = require('mini.deps')

deps.add({ source = 'echasnovski/mini.diff' })

require('mini.diff').setup({
    view = {
        style = 'sign',
        signs = { add = '▎', change = '▎', delete = '▁' },
        priority = 199,
    },

    mappings = {
        apply = 'gh',
        reset = 'gH',
        textobject = 'gh',
        goto_first = '[H',
        goto_prev = '[h',
        goto_next = ']h',
        goto_last = ']H',
    },

    options = {
        algorithm = 'myers',
        indent_heuristic = true,
        linematch = 60,
        wrap_goto = false,
    },
})
