local deps = require('mini.deps')

deps.add({ source = 'nvim-mini/mini.indentscope', checkout = 'stable' })

local indentscope = require('mini.indentscope')
indentscope.setup({
    draw = {
        animation = indentscope.gen_animation.none(),
    },
})
