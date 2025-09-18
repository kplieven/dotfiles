local deps = require('mini.deps')

deps.add({ source = 'nvim-mini/mini.map', checkout = 'stable' })

local map = require('mini.map')

map.setup({
    integrations = {
        map.gen_integration.diagnostic({
            error = 'DiagnosticFloatingError',
            warn  = 'DiagnosticFloatingWarn',
            info  = 'DiagnosticFloatingInfo',
            hint  = 'DiagnosticFloatingHint',
        }),
        map.gen_integration.builtin_search(),
        map.gen_integration.diff(),
    },

    symbols = {
        encode = map.gen_encode_symbols.dot('4x2'),
        scroll_line = '█',
        scroll_view = '┃',
    },
    window = {
        width = 8
    },
})

vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'lua', 'python', 'javascript', 'typescript', 'cpp' },
    callback = function()
        map.open()
    end,
})

vim.keymap.set('n', '<leader>mt', function()
    map.toggle()
end, { desc = 'Toggle minimap' })

local wk = require('which-key')
wk.add({
    { '<leader>m', group = 'Map' },
})
