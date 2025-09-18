local deps = require('mini.deps')

deps.add({ source = 'echasnovski/mini.files' })

require('mini.files').setup()

vim.keymap.set('n', '<leader>e', function()
    require('mini.files').open()
end, { desc = 'File explorer' })

local wk = require('which-key')
wk.add({
    { '<leader>e', desc = 'File explorer', group = 'Explorer' },
})
