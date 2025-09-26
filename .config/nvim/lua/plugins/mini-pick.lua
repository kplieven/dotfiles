local deps = require('mini.deps')

deps.add({ source = 'echasnovski/mini.pick' })

require('mini.pick').setup()

local builtin = require('mini.pick').builtin
vim.keymap.set('n', '<leader>f', builtin.files, { desc = 'Find files' })
-- vim.keymap.set('n', '<leader>st', builtin.grep_live, { desc = 'Search text' })
vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = 'Resume previous search' })
vim.keymap.set('n', '<leader>sw', function()
    builtin.grep({ pattern = vim.fn.expand('<cword>') })
end, { desc = 'Search current word' })

local wk = require('which-key')
wk.add({
    { '<leader>s', group = 'Search' },
})
