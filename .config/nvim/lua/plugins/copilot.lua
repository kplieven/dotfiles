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
            vim.notify('Building CopilotChat...', vim.log.levels.INFO)
            local out = vim.system({ 'make', 'tiktoken' }, { cwd = plugin_path }):wait()
            if out.code == 0 then
                vim.notify('CopilotChat build successful!', vim.log.levels.INFO)
            else
                vim.notify('CopilotChat build failed: ' .. (out.stderr or ''), vim.log.levels.ERROR)
            end
        end,
    }
})

require('copilot').setup({
    panel = { enabled = false },
    suggestion = { enabled = false },
})

require('CopilotChat').setup({
    debug = false,
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
