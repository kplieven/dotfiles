-- general
lvim.log.level = "warn"
lvim.format_on_save = false
lvim.colorscheme = "tokyonight"

lvim.leader = "space"
lvim.keys.normal_mode["<C-s>"] = ":w<cr>"
lvim.keys.normal_mode["<C-t>"] = ":tabe<cr>"
lvim.keys.normal_mode["<leader>o"] = ":ClangdSwitchSourceHeader<cr>"
lvim.keys.normal_mode["L"] = ":bnext<cr>"
lvim.keys.normal_mode["H"] = ":bprev<cr>"
lvim.keys.normal_mode["<S-Left>"] = ":bprev<cr>"
lvim.keys.normal_mode["<S-Right>"] = ":bnext<cr>"
lvim.keys.normal_mode["<C-Left>"] = "<C-W>h"
lvim.keys.normal_mode["<C-Down>"] = "<C-W>j"
lvim.keys.normal_mode["<C-Up>"] = "<C-W>k"
lvim.keys.normal_mode["<C-Right>"] = "<C-W>l"
lvim.keys.normal_mode["<Leader>bo"] = ':%bd!|e #|bd #|normal`"<CR>'
lvim.keys.normal_mode["ca"] = "<cmd>lua vim.lsp.buf.code_action()<CR>"

lvim.keys.normal_mode["<F8>"] = ":Gitsigns stage_hunk<cr>"
lvim.keys.normal_mode["<F9>"] = ":Gitsigns next_hunk<cr>"
lvim.keys.normal_mode["<F10>"] = ":Gitsigns prev_hunk<cr>"
lvim.keys.normal_mode["<F11>"] = ":Gitsigns reset_hunk<cr>"
lvim.keys.normal_mode["<F12>"] = ":Gitsigns preview_hunk<cr>"

vim.opt.relativenumber = true
vim.opt.wrap = true
vim.opt.tabstop = 4
vim.opt.sts = 4
vim.opt.sw = 4

-- ALPHA
lvim.builtin.alpha.active = true
lvim.builtin.alpha.mode = "dashboard"

lvim.builtin.alpha.dashboard.section.header.val = {
    [[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⡐⠰⠠⠄⡀⢄⠒⣠⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀]],
    [[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣧⠹⢓⢡⣊⡔⣈⠛⡬⣃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀]],
    [[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣃⠳⡎⠣⢜⠌⠣⡞⠴⣉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀]],
    [[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⠄⢂⣁⡿⢘⢓⠡⢺⣈⠑⣞⠰⢨⠘⠰⢠⢀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀]],
    [[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⠄⢂⣡⠴⢚⠩⠄⣟⢦⣌⠣⢱⢂⡑⢮⠐⣩⢄⡁⠂⠌⠒⠡⢂⠄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀]],
    [[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⢄⣂⠡⡴⡬⢯⡰⢌⠢⡑⠌⡇⡘⡎⠰⢹⢠⠘⡼⢈⢼⠠⡘⡑⠪⢄⡁⠂⠌⡐⠡⢂⠄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀]],
    [[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠂⡔⠱⣥⢂⠍⡓⠮⣍⠳⣜⡌⡳⣌⢧⠱⠛⠲⣡⡝⠦⠞⡰⢡⡘⣥⠮⣙⡳⠦⢀⡁⢂⣬⢲⡱⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀]],
    [[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡈⡔⠜⠡⣎⢭⡓⢮⣱⠌⠫⣔⠮⣑⠮⢆⡥⣉⠒⠤⡘⢄⣣⠖⠧⣙⢴⠪⠑⡁⡢⠔⠌⢫⢖⣣⠳⣥⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀]],
    [[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡐⠰⡘⠨⡐⣭⢲⡙⡦⢽⠀⠄⡀⢺⠔⡙⠦⣍⡚⠵⣦⠏⣚⠥⡚⠍⠊⢄⢢⠱⠘⡈⠄⠡⠚⡜⢦⡛⡴⡂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀]],
    [[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠠⣐⡞⢠⢓⡤⠁⣆⢧⢣⡝⡼⣹⠀⠒⠠⢸⡓⢮⣑⠢⢉⠳⢞⠚⠡⢁⡂⢜⠊⡂⢁⠢⠑⡉⠄⡁⢂⢹⢣⡝⣲⢱⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀]],
    [[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡰⠢⢏⡵⢀⡣⢝⡼⡩⡔⢯⡲⣝⡲⣹⢀⠡⢂⢡⡛⢦⡍⣏⠳⡍⠤⣸⠴⡍⠈⠄⢂⠃⢡⠈⠔⡀⠒⡈⠄⡈⢷⡸⣅⢏⠞⣠⠵⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀]],
    [[⠀⠀⠀⠀⠀⠀⠀⠀⡠⣐⠌⡀⢂⡐⠠⠬⢇⡊⠐⠇⣈⠑⠣⡳⢭⠗⢂⠰⢀⠢⡝⢦⡹⣌⢯⠃⣴⢣⢻⠴⠁⠌⡠⠌⠠⢈⡐⠠⢁⠰⠐⡀⢣⠗⡸⠍⠊⠄⠀⠑⣂⠄⠀⠀⠀⠀⠀⠀⠀⠀]],
    [[⠀⠀⠀⠀⠀⠀⠀⠀⡱⠌⡒⣄⡡⢀⠁⡂⠄⡉⠱⢢⣈⠵⣀⢱⡤⣌⡤⢆⡄⠢⣝⢮⡱⢎⠇⣰⢎⢧⠻⣜⢃⠐⢠⠈⠄⠡⢀⡁⠂⠤⢁⠐⡠⢉⠐⠈⠀⢀⠤⣂⠥⡚⠀⠀⠀⠀⠀⠀⠀⠀]],
    [[⠀⠀⠀⠀⠀⠀⠀⠀⠈⠐⠌⡐⠕⠲⣌⡐⢀⠂⣁⠂⣍⠼⠨⢊⡐⠍⡞⣱⡚⢗⡺⣌⡳⠏⢰⢣⠞⣬⢻⡌⣏⡐⠠⢈⡐⢁⠂⠄⣁⠢⠐⡈⠐⠀⢀⡤⣺⡙⠤⠡⠂⠁⠀⠀⠀⠀⠀⠀⠀⠀]],
    [[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⡒⢅⡂⢽⠲⣤⡀⠜⢣⡀⡁⢂⢉⠖⢌⡀⠛⢆⡈⠑⡏⢠⠟⣬⢛⡴⢫⡜⡼⢤⠁⢂⠐⠠⡈⢐⠀⠂⠁⢀⠤⣺⢇⡳⢥⡃⠆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀]],
    [[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢡⠨⡝⣎⢳⣱⠘⡲⢄⡉⠲⠤⠃⡈⠄⠋⠦⢄⣨⠝⢠⡛⡼⢢⢏⡜⣳⠼⠑⢧⠊⠄⡈⠡⠐⠀⣀⠤⠊⡏⠀⡇⢯⡜⣣⠗⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀]],
    [[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡌⠷⣜⡣⢞⢸⠖⢔⡉⠖⡤⡁⡐⢈⠰⠐⡈⠄⠌⢶⢹⡜⣣⡎⠓⣍⠖⠋⠄⠌⠐⠀⢁⡤⡎⡅⠐⡀⢇⡡⣏⢶⣩⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀]],
    [[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠻⡴⣩⢛⡦⡰⢂⠌⠡⠀⡟⡴⢌⡠⢁⠐⡈⡐⠠⠑⢪⠥⠔⢋⠠⢈⠐⠈⣀⠔⣮⢋⡖⣇⡁⠒⣸⠁⡼⠎⠂⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀]],
    [[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠧⢋⠶⣙⠧⣌⡠⢁⠝⢄⠒⠅⡳⢠⡐⠠⠁⠌⢢⠀⡇⠀⠂⣀⠴⣚⠄⠂⣧⠛⡈⠡⢙⢢⠅⡘⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀]],
    [[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠊⢷⣡⢛⡼⢆⡊⢱⠆⣌⠒⢉⡳⠌⡐⡃⠤⡁⠔⢮⢣⡛⣜⢂⣡⠄⢂⡔⠣⡩⠐⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀]],
    [[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠳⡜⣭⢹⢨⣇⠀⡉⠢⢄⠑⡤⢉⡌⠔⢊⡰⣣⠝⡼⠁⡦⠘⡣⠩⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀]],
    [[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠁⠫⡳⣌⠻⡤⣅⣈⠳⢦⢤⢴⡘⣭⢖⡵⢫⠇⡠⠕⢉⠐⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀]],
    [[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠳⡱⢎⡼⣘⢧⡚⣬⢱⡙⡮⠜⠓⠈    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀]],
    [[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠑⠮⡕⢮⡱⠆⠒⠉⠀⠀⠀⠀   ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀]],
    [[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⠁⠋⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀]],
}
lvim.builtin.alpha.dashboard.section.footer.val = "click clack"
lvim.builtin.terminal.active = true
lvim.builtin.nvimtree.setup.view.side = "left"
lvim.builtin.nvimtree.setup.renderer.icons.show.git = false
lvim.builtin.dap.active = true;

lvim.builtin.treesitter.ensure_installed = {
    "bash",
    "c",
    "javascript",
    "json",
    "lua",
    "python",
    "typescript",
    "tsx",
    "css",
    "rust",
    "java",
    "yaml",
}

lvim.builtin.treesitter.ignore_install = { "haskell" }
lvim.builtin.treesitter.highlight.enabled = true

-- set a formatter, this will override the language server formatting capabilities (if it exists)
local formatters = require "lvim.lsp.null-ls.formatters"
formatters.setup {
    { command = "black", filetypes = { "python" } },
}

-- DAP configuration
local dap = require('dap')
-- C++
dap.adapters.lldb = {
    type = 'executable',
    command = '/home/karlie/Repositories/llvm-project/build/bin/lldb-vscode', -- adjust as needed, must be absolute path
    name = 'lldb'
}
dap.adapters.cppdbg = {
    id = 'cppdbg',
    type = 'executable',
    command = '/home/karlie/vscode-cpptools-linux/extension/debugAdapters/bin/OpenDebugAD7',
}

dap.configurations.cpp = {
    {
        name = 'Launch',
        type = 'lldb',
        request = 'launch',
        cwd = '${workspaceFolder}',
        stopOnEntry = false,
        program = function()
            return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
        end,
        setupCommands = {
            {
                description = "Enable pretty-printing for gdb",
                text = "-enable-pretty-printing",
                ignoreFailures = true
            },
        },
    },
    {
        name = 'Attach to delirium',
        type = 'cppdbg',
        request = 'launch',
        MIMode = 'gdb',
        miDebuggerPath = '/home/karlie/Brewery/w3delirium/tools/w3delirium-sdk/bin/x86_64-linux-gdb',
        miDebuggerServerAddress = '10.200.18.100:1234',
        cwd = '${workspaceFolder}',
        stopOnEntry = true,
        externalConsole = false,
        program = function()
            return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
        end,
        setupCommands = {
            {
                description = "Enable pretty-printing for gdb",
                text = "-enable-pretty-printing",
                ignoreFailures = true
            },
        },
    },
    {
        name = 'Attach to phoenix',
        type = 'cppdbg',
        request = 'launch',
        MIMode = 'gdb',
        miDebuggerPath = '/home/karlie/Brewery/w3phoenix/tools/w3phoenix-sdk/bin/x86_64-linux-gdb',
        miDebuggerServerAddress = '10.200.18.118:1234',
        cwd = '${workspaceFolder}',
        stopOnEntry = true,
        externalConsole = false,
        program = function()
            return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
        end,
        setupCommands = {
            {
                description = "Enable pretty-printing for gdb",
                text = "-enable-pretty-printing",
                ignoreFailures = true
            },
        },
    },
    {
        name = 'Attach to kirin',
        type = 'cppdbg',
        request = 'launch',
        MIMode = 'gdb',
        miDebuggerPath = '/home/karlie/Brewery/w3kirin/tools/w3kirin-sdk/bin/aarch64-linux-gdb',
        miDebuggerServerAddress = '10.200.18.113:1234',
        cwd = '${workspaceFolder}',
        stopOnEntry = true,
        externalConsole = false,
        program = function()
            return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
        end,
        setupCommands = {
            {
                description = "Enable pretty-printing for gdb",
                text = "-enable-pretty-printing",
                ignoreFailures = true
            },
        },
    }
}
dap.configurations.c = dap.configurations.cpp
dap.configurations.rust = dap.configurations.cpp

-- Python
dap.adapters.python = {
    type = 'executable',
    command = '/home/karlie/.virtualenvs/debugpy/bin/python',
    args = { '-m', 'debugpy.adapter' },
}

dap.configurations.python = {
    {
        -- The first three options are required by nvim-dap
        type = 'python', -- the type here established the link to the adapter definition: `dap.adapters.python`
        request = 'launch',
        name = "Launch file",
        -- Options below are for debugpy, see https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for supported options

        program = "${file}", -- This configuration will launch the current file if used.
        pythonPath = function()
            -- debugpy supports launching an application with a different interpreter then the one used to launch debugpy itself.
            -- The code below looks for a `venv` or `.venv` folder in the current directly and uses the python within.
            -- You could adapt this - to for example use the `VIRTUAL_ENV` environment variable.
            local cwd = vim.fn.getcwd()
            if vim.fn.executable(cwd .. '/venv/bin/python') == 1 then
                return cwd .. '/venv/bin/python'
            elseif vim.fn.executable(cwd .. '/.venv/bin/python') == 1 then
                return cwd .. '/.venv/bin/python'
            else
                return '/usr/bin/python3'
            end
        end,
    },
}

vim.keymap.set("n", "<F1>", function() dap.toggle_breakpoint() end)
vim.keymap.set("n", "<F2>", function() dap.continue() end)
vim.keymap.set("n", "<F3>", function()
    dap.terminate()
    dap.close()
    require 'dapui'.toggle()
end)
vim.keymap.set("n", "<F4>", function() dap.step_out() end)
vim.keymap.set("n", "<F5>", function() dap.step_into() end)
vim.keymap.set("n", "<F6>", function() dap.step_over() end)
vim.keymap.set("n", "<F7>", function() dap.run_to_cursor() end)

-- Additional Plugins
lvim.plugins = {
    { "psliwka/vim-smoothie" },
    {
        "tpope/vim-fugitive",
        cmd = {
            "G",
            "Git",
            "Gdiffsplit",
            "Gread",
            "Gwrite",
            "Ggrep",
            "GMove",
            "GDelete",
            "GBrowse",
            "GRemove",
            "GRename",
            "Glgrep",
            "Gedit"
        },
        ft = { "fugitive" }
    },
    {
        "echasnovski/mini.map",
        branch = "stable",
        config = function()
            require('mini.map').setup()
            local map = require('mini.map')
            map.setup({
                integrations = {
                    map.gen_integration.builtin_search(),
                    map.gen_integration.diagnostic({
                        error = 'DiagnosticFloatingError',
                        warn  = 'DiagnosticFloatingWarn',
                        info  = 'DiagnosticFloatingInfo',
                        hint  = 'DiagnosticFloatingHint',
                    }),
                },
                symbols = {
                    encode = map.gen_encode_symbols.dot('4x2'),
                },
                window = {
                    focusable = true,
                    side = 'right',
                    width = 8, -- set to 1 for a pure scrollbar :)
                    winblend = 30,
                    show_integration_count = false,
                },
            })
        end
    },
    {
        "folke/trouble.nvim",
        cmd = "TroubleToggle",
    },
    {
        'tamton-aquib/duck.nvim',
        config = function()
            lvim.keys.normal_mode["<Leader>Dd"] = function() require("duck").hatch() end
            lvim.keys.normal_mode["<Leader>Dm"] = function() require("duck").hatch("🐕", 0.5) end
            lvim.keys.normal_mode["<Leader>Dk"] = function() require("duck").cook() end
        end
    },
    {
        "iamcco/markdown-preview.nvim",
        cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
        build = "cd app && yarn install",
        init = function()
            vim.g.mkdp_filetypes = { "markdown" }
        end,
        ft = { "markdown" },
    },
    {
        "aklt/plantuml-syntax"
    },
    {
        "tyru/open-browser.vim"
    },
    {
        "weirongxu/plantuml-previewer.vim"
    },
    {
        "doums/darcula"
    },
    {
        "folke/tokyonight.nvim"
    },
    {
        "folke/todo-comments.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        opts = {
            -- your configuration comes here
            -- or leave it empty to use the default settings
            -- refer to the configuration section below
        }
    },
    {
        "folke/flash.nvim",
        event = "VeryLazy",
        ---@type Flash.Config
        opts = {},
        keys = {
            {
                "s",
                mode = { "n", "x", "o" },
                function()
                    require("flash").jump()
                end,
                desc = "Flash",
            },
            {
                "S",
                mode = { "n", "o", "x" },
                function()
                    require("flash").treesitter()
                end,
                desc = "Flash Treesitter",
            },
            {
                "r",
                mode = "o",
                function()
                    require("flash").remote()
                end,
                desc = "Remote Flash",
            },
            {
                "R",
                mode = { "o", "x" },
                function()
                    require("flash").treesitter_search()
                end,
                desc = "Flash Treesitter Search",
            },
            {
                "<c-s>",
                mode = { "c" },
                function()
                    require("flash").toggle()
                end,
                desc = "Toggle Flash Search",
            },
        },
    },
    --     "andrewferrier/debugprint.nvim",
    --     config = function()
    --         require("debugprint").setup({create_keymaps = false, create_commands = false})
    --     end,
    -- },
}

-- Plugin whichkey
lvim.builtin.which_key.mappings["t"] = {
    name = "Diagnostics",
    t = { "<cmd>TroubleToggle<cr>", "trouble" },
    w = { "<cmd>TroubleToggle workspace_diagnostics<cr>", "workspace" },
    d = { "<cmd>TroubleToggle document_diagnostics<cr>", "document" },
    q = { "<cmd>TroubleToggle quickfix<cr>", "quickfix" },
    l = { "<cmd>TroubleToggle loclist<cr>", "loclist" },
    r = { "<cmd>TroubleToggle lsp_references<cr>", "references" },
}

lvim.builtin.which_key.mappings["D"] = {
    name = "Duck",
    d = { "spawn duck" },
    m = { "spawn dog" },
    k = { "cook" },
}

lvim.autocommands = {
    {
        { "BufEnter", "Filetype" },
        {
            desc = "Open mini.map and exclude some filetypes",
            pattern = { "*" },
            callback = function()
                local exclude_ft = {
                    "qf",
                    "NvimTree",
                    "toggleterm",
                    "TelescopePrompt",
                    "alpha",
                    "netrw",
                    "log",
                }

                local map = require('mini.map')
                if vim.tbl_contains(exclude_ft, vim.o.filetype) then
                    vim.b.minimap_disable = true
                    map.close()
                elseif vim.o.buftype == "" then
                    map.open()
                end
            end,
        },
    },
}
