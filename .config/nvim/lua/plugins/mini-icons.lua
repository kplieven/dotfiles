local deps = require('mini.deps')

deps.add({ source = 'nvim-mini/mini.icons', checkout = 'stable' })

require('mini.icons').setup()
