vim.pack.add({ { src = 'https://github.com/nvim-mini/mini.indentscope', version = 'stable' } })

local indentscope = require('mini.indentscope')
indentscope.setup({
    draw = {
        animation = indentscope.gen_animation.none(),
    },
})
