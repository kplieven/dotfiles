local deps = require('mini.deps')

deps.add({
    source = 'CopilotC-Nvim/CopilotChat.nvim',
    checkout = 'main',
    depends = {
        'zbirenbaum/copilot.lua',
        'nvim-lua/plenary.nvim',
    },
    hooks = {
        post_install = function()
            local plugin_path = vim.fn.stdpath('data') .. '/site/pack/deps/opt/CopilotChat.nvim'
            print('Building CopilotChat...')
            local result = vim.fn.system('cd ' .. plugin_path .. ' && make tiktoken')
            local exit_code = vim.v.shell_error

            if exit_code == 0 then
                print('CopilotChat build successful!')
            else
                print('CopilotChat build failed:', result)
            end
        end,
        post_update = function()
            local plugin_path = vim.fn.stdpath('data') .. '/site/pack/deps/opt/CopilotChat.nvim'
            print('Rebuilding CopilotChat...')
            local result = vim.fn.system('cd ' .. plugin_path .. ' && make tiktoken')
            local exit_code = vim.v.shell_error

            if exit_code == 0 then
                print('CopilotChat rebuild successful!')
            else
                print('CopilotChat rebuild failed:', result)
            end
        end,
    }
})

require('copilot').setup({
    panel = { enabled = false },
    suggestion = { enabled = false },
})

require('CopilotChat').setup({
    debug = true,
})

-- Optional: Add some useful keymaps
vim.keymap.set({'n', 'v'}, '<leader>cc', '<cmd>CopilotChatToggle<cr>', { desc = 'Toggle Copilot Chat' })
vim.keymap.set('v', '<leader>ce', '<cmd>CopilotChatExplain<cr>', { desc = 'Explain selected code' })
vim.keymap.set('v', '<leader>cr', '<cmd>CopilotChatReview<cr>', { desc = 'Review selected code' })
vim.keymap.set('v', '<leader>cf', '<cmd>CopilotChatFix<cr>', { desc = 'Fix selected code' })
vim.keymap.set('v', '<leader>co', '<cmd>CopilotChatOptimize<cr>', { desc = 'Optimize selected code' })

-- Which-key entries
local wk = require('which-key')
wk.add({
    { '<leader>cc', desc = 'Open Copilot Chat' },
    { '<leader>ce', desc = 'Explain selected code',  mode = 'v' },
    { '<leader>cr', desc = 'Review selected code',   mode = 'v' },
    { '<leader>cf', desc = 'Fix selected code',      mode = 'v' },
    { '<leader>co', desc = 'Optimize selected code', mode = 'v' },
})
