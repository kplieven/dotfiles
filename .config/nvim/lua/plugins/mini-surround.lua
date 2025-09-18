local deps = require('mini.deps')

deps.add({ source = 'nvim-mini/mini.surround', checkout = 'stable' })

vim.keymap.set({ 'n', 'x' }, 's', '<Nop>')

require('mini.surround').setup()
