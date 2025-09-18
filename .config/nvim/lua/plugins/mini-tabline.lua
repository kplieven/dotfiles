local deps = require('mini.deps')

deps.add({ source = 'nvim-mini/mini.tabline', checkout = 'stable' })

require('mini.tabline').setup({
    show_icons = true,
    format = function(buf_id, label)
        local suffix = vim.api.nvim_buf_get_option(buf_id, 'modified') and '● ' or '  '
        return MiniTabline.default_format(buf_id, label) .. suffix
    end,
})

vim.keymap.set('n', 'L', '<cmd>bnext<cr>', { desc = 'Next buffer' })
vim.keymap.set('n', 'H', '<cmd>bprev<cr>', { desc = 'Previous buffer' })
vim.keymap.set('n', '<S-Left>', '<cmd>bprev<cr>', { desc = 'Previous buffer' })
vim.keymap.set('n', '<S-Right>', '<cmd>bnext<cr>', { desc = 'Next buffer' })
vim.keymap.set('n', '<leader>bc', '<cmd>bd<cr>', { desc = 'Close buffer' })

local function close_all_buffers_but_current()
    local current_buf = vim.api.nvim_get_current_buf()
    local all_bufs = vim.api.nvim_list_bufs()

    for _, buf in ipairs(all_bufs) do
        if buf ~= current_buf and vim.api.nvim_buf_is_loaded(buf) then
            vim.api.nvim_buf_delete(buf, { force = false })
        end
    end
end
vim.keymap.set('n', '<leader>bo', close_all_buffers_but_current, { desc = 'Close other buffers' })

local wk = require('which-key')
wk.add({
    { '<leader>b', group = 'Buffer' },
})
