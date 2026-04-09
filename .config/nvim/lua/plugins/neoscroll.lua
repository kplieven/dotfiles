vim.pack.add({ 'https://github.com/karb94/neoscroll.nvim' })

require('neoscroll').setup({
    duration_multiplier = 0.5,
    easing = 'cubic'
})
