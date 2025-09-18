local deps = require('mini.deps')

deps.add({ source = 'nvim-mini/mini.pairs', checkout = 'stable' })

require('mini.pairs').setup()
