vim.pack.add({ 'https://github.com/goolord/alpha-nvim' })

local alpha = require('alpha')
local dashboard = require('alpha.themes.dashboard')

dashboard.section.buttons.val = {
    dashboard.button('f', ' ' .. ' Find file',  "<cmd>lua require('fzf-lua').files()<CR>"),
    dashboard.button('n', ' ' .. ' New file',   ':ene <BAR> startinsert <CR>'),
    dashboard.button('g', ' ' .. ' Find text',  "<cmd>lua require('fzf-lua').live_grep()<CR>"),
    dashboard.button('c', ' ' .. ' Config',     ':e $MYVIMRC <CR>'),
    dashboard.button('q', ' ' .. ' Quit',       ':qa<CR>'),
}

dashboard.config.opts.noautocmd = true
alpha.setup(dashboard.opts)
