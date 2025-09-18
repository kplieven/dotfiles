local deps = require('mini.deps')

deps.add({ source = 'echasnovski/mini.comment' })

require('mini.comment').setup()

vim.keymap.set('n', '<leader>/', 'gcc', { remap = true, desc = 'Comment line' })
vim.keymap.set('x', '<leader>/', 'gc', { remap = true, desc = 'Comment selection' })

local wk = require('which-key')
wk.add({
    { '<leader>/', desc = 'Toggle comment' },
})
