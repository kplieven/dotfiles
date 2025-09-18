local deps = require('mini.deps')

deps.add({ source = 'nvim-mini/mini.trailspace', checkout = 'stable' })

require('mini.trailspace').setup()
