-- Copilot chat keymaps
vim.keymap.set('n', '<leader><Tab>', ':CopilotChatToggle<CR>', { desc = "Toggle Copilot Chat" })
vim.keymap.set('v', '<leader><Tab>', ':CopilotChatExplain<CR>', { desc = "Explain the current selection" })
