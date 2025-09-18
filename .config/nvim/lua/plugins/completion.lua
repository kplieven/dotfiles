local deps = require('mini.deps')

deps.add({
    source = 'saghen/blink.cmp',
    depends = {
        'giuxtaposition/blink-cmp-copilot',
    },
    hooks = {
        post_install = function()
            local plugin_path = vim.fn.stdpath('data') .. '/site/pack/deps/opt/blink.cmp'
            print('Building Blink...')
            local result = vim.fn.system('cd ' .. plugin_path .. ' && cargo build --release')
            local exit_code = vim.v.shell_error

            if exit_code == 0 then
                print('Blink build successful!')
            else
                print('Blink build failed: ', result)
            end
        end,
        post_update = function()
            local plugin_path = vim.fn.stdpath('data') .. '/site/pack/deps/opt/blink.cmp'
            print('Rebuilding Blink...')
            local result = vim.fn.system('cd ' .. plugin_path .. ' && cargo build --release')
            local exit_code = vim.v.shell_error

            if exit_code == 0 then
                print('Blink rebuild successful!')
            else
                print('Blink rebuild failed: ', result)
            end
        end,
    }
})

require('blink.cmp').setup({
    keymap = {
        preset = 'enter',
        ['<Tab>'] = { 'select_next', 'fallback' },
        ['<S-Tab>'] = { 'select_prev', 'fallback' },
    },
    sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer', 'copilot' },
        providers = {
            copilot = {
                name = 'copilot',
                module = 'blink-cmp-copilot',
                score_offset = 100,
                async = true,
            },
        },
    },
    completion = {
        documentation = {
            auto_show = true,
            auto_show_delay_ms = 120,
            window = {
                border       = 'rounded',
                max_width    = 80,
                max_height   = 20,
                winhighlight =
                'Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:BlinkCmpDocCursorLine',
            },
        },

        list = { selection = { preselect = true, auto_insert = false } },
        ghost_text = { enabled = true, show_with_menu = false },
    },
})

local function show_copilot_only()
    require('blink.cmp').show({
        sources = { 'copilot' }
    })
end

vim.api.nvim_create_user_command('CopilotSuggest', show_copilot_only, { desc = 'Show Copilot suggestions' })

vim.keymap.set('n', '<leader>cp', function()
    vim.cmd('startinsert')
    vim.defer_fn(function()
        show_copilot_only()
    end, 50)
end, { desc = 'Show Copilot suggestions' })

vim.keymap.set('i', '<C-g>', show_copilot_only, { desc = 'Show Copilot completions' })
