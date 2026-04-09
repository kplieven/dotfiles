local deps = require('mini.deps')

deps.add({ source = 'nvim-mini/mini-git', checkout = 'stable' })

require('mini.git').setup()

local wk = require('which-key')

vim.keymap.set('n', '<leader>gb', MiniGit.show_at_cursor,      { desc = 'Git blame/info at cursor' })
vim.keymap.set({'n', 'v'}, '<leader>gh', MiniGit.show_range_history, { desc = 'Git range history' })

wk.add({
    { '<leader>g', group = 'Git' },
})
