local deps = require('mini.deps')

deps.add({ source = 'nvim-mini/mini.notify', checkout = 'stable' })

require('mini.notify').setup()
