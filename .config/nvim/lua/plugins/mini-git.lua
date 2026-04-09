vim.pack.add({ { src = 'https://github.com/nvim-mini/mini-git', version = 'stable' } })

require('mini.git').setup()

local wk = require('which-key')

vim.keymap.set('n', '<leader>gb', MiniGit.show_at_cursor,      { desc = 'Git blame/info at cursor' })
vim.keymap.set({'n', 'v'}, '<leader>gh', MiniGit.show_range_history, { desc = 'Git range history' })

wk.add({
    { '<leader>g', group = 'Git' },
})
