local deps = require('mini.deps')

deps.add({ source = 'nvim-mini/mini.cursorword', checkout = 'stable' })

require('mini.cursorword').setup()
