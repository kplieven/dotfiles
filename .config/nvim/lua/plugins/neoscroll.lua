local deps = require('mini.deps')

deps.add({ source = 'karb94/neoscroll.nvim' })

require('neoscroll').setup({
    duration_multiplier = 0.5,
    easing = 'cubic'
})
