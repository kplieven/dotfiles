local deps = require('mini.deps')

deps.add({
    source = 'mistricky/codesnap.nvim',
    hooks = {
        post_install = function()
            local plugin_path = vim.fn.stdpath('data') .. '/site/pack/deps/opt/codesnap.nvim'
            print('Building CodeSnap...')
            local result = vim.fn.system('cd ' .. plugin_path .. ' && make')
            local exit_code = vim.v.shell_error

            if exit_code == 0 then
                print('CodeSnap build successful!')
            else
                print('CodeSnap build failed: ', result)
            end
        end,
        post_update = function()
            local plugin_path = vim.fn.stdpath('data') .. '/site/pack/deps/opt/codesnap.nvim'
            print('Rebuilding CodeSnap...')
            local result = vim.fn.system('cd ' .. plugin_path .. ' && make')
            local exit_code = vim.v.shell_error

            if exit_code == 0 then
                print('CodeSnap rebuild successful!')
            else
                print('CodeSnap rebuild failed: ', result)
            end
        end,
    }
})

require('codesnap').setup({
    watermark = '',
    save_path = '~/Pictures/codesnap/test.png',
    code_font_family = 'JetBrainsMono Nerd Font',
    has_breadcrumbs = true,
    bg_theme = 'dusk',
    bg_x_padding = 32,
    bg_y_padding = 22,
    has_line_number = true,
    show_workspace = true,
})

-- Keymaps for CodeSnap
vim.keymap.set('x', '<leader>cs', '<cmd>CodeSnap<cr>', { desc = 'Save code snapshot' })
vim.keymap.set('x', '<leader>cy', '<cmd>CodeSnapSave<cr>', { desc = 'Copy code snapshot' })

-- Which-key entries
local wk = require('which-key')
wk.add({
    { '<leader>c',  group = 'Code',              mode = 'x' },
    { '<leader>cs', desc = 'Save code snapshot', mode = 'x' },
    { '<leader>cy', desc = 'Copy code snapshot', mode = 'x' },
})
