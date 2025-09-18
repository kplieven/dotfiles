-- Navigation
vim.keymap.set('n', '<C-Left>', '<C-W>h')
vim.keymap.set('n', '<C-H>', '<C-W>h')
vim.keymap.set('n', '<C-Down>', '<C-W>j')
vim.keymap.set('n', '<C-Up>', '<C-W>k')
vim.keymap.set('n', '<C-Right>', '<C-W>l')
vim.keymap.set('n', '<C-L>', '<C-W>l')

-- Remove highlighting
vim.keymap.set('n', '<leader>rh', ':nohlsearch<CR>', { desc = 'Remove highlighting' })

-- Keymaps for better default experience
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })

-- C++ specific
vim.keymap.set('n', '<leader>o', ':LspClangdSwitchSourceHeader<CR>', { desc = 'Switch source/header file' })

-- Highlight on yank
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
    callback = function()
        vim.highlight.on_yank()
    end,
    group = highlight_group,
    pattern = '*',
})

-- Yank the current location of the cursor in the codebase
vim.api.nvim_create_user_command('YankLocation', function()
    local line_number = vim.fn.line('.')
    local relative_path = vim.fn.fnamemodify(vim.fn.expand('%:h'), ':p:~:.') .. vim.fn.expand('%:t')

    local content = string.format('%s:%d', relative_path, line_number)

    vim.fn.setreg('+', content)
    vim.notify('Copied "' .. content .. '" to the clipboard!')
end, {})
vim.keymap.set('n', 'yl', ':YankLocation<CR>', { desc = 'Yank current location of cursor' })
