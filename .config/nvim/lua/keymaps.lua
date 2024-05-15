-- [[ Basic Keymaps ]]

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })

-- C++ specific
vim.keymap.set('n', '<leader>o', ':ClangdSwitchSourceHeader<CR>', { desc = 'Switch source/header file' })

-- Navigation
vim.keymap.set('n', 'L', ':bnext<CR>')
vim.keymap.set('n', 'H', ':bprev<CR>')
vim.keymap.set('n', '<S-Left>', ':bprev<CR>')
vim.keymap.set('n', '<S-Right>', ':bnext<CR>')
vim.keymap.set('n', '<C-Left>', '<C-W>h')
vim.keymap.set('n', '<C-Down>', '<C-W>j')
vim.keymap.set('n', '<C-Up>', '<C-W>k')
vim.keymap.set('n', '<C-Right>', '<C-W>l')

-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})

-- Yank the location of the current cursor
vim.api.nvim_create_user_command("YankLocation", function()
    local line_number = vim.fn.line('.')
    local relative_path = vim.fn.fnamemodify(vim.fn.expand('%:h'), ':p:~:.') .. vim.fn.expand('%:t')

    local content = string.format('%s:%d', relative_path, line_number)

    vim.fn.setreg("+", content)
    vim.notify('Copied "' .. content .. '" to the clipboard!')
end, {})
vim.keymap.set('n', 'yl', ':YankLocation<CR>', { desc = "[Y]ank current [L]ocation of cursor" })

-- Remove highlighting
vim.keymap.set('n', '<leader>h', ':nohlsearch<CR>', { desc = "Remove [H]ighlighting" })
