vim.pack.add({ { src = 'https://github.com/nvim-mini/mini.surround', version = 'stable' } })

vim.keymap.set({ 'n', 'x' }, 's', '<Nop>')

require('mini.surround').setup()
