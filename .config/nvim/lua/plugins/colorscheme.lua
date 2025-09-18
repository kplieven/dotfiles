local deps = require('mini.deps')

deps.add({ source = 'catppuccin/nvim', name = 'catppuccin' })
deps.add({ source = 'folke/tokyonight.nvim', name = 'tokyonight' })

vim.cmd.colorscheme 'tokyonight-night'
