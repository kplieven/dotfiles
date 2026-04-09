vim.pack.add({
    'https://github.com/zbirenbaum/copilot.lua',
    'https://github.com/nvim-lua/plenary.nvim',
    { src = 'https://github.com/CopilotC-Nvim/CopilotChat.nvim', version = 'main' },
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
