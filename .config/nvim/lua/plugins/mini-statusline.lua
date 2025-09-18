local deps = require('mini.deps')

deps.add({ source = 'nvim-mini/mini.statusline', checkout = 'stable' })

require('mini.statusline').setup()
