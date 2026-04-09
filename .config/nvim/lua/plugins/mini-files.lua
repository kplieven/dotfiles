vim.pack.add({ 'https://github.com/echasnovski/mini.files' })

require('mini.files').setup({
    mappings = {
        go_in_plus = '<CR>',
    }
})

vim.keymap.set('n', '<leader>e', function()
    require('mini.files').open()
end, { desc = 'File explorer' })

local wk = require('which-key')
wk.add({
    { '<leader>e', desc = 'File explorer', group = 'Explorer' },
})
