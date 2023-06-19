--[[
lvim is the global options object

Linters should be
filled in as strings with either
a global executable or a path to
an executable
]]
-- THESE ARE EXAMPLE CONFIGS FEEL FREE TO CHANGE TO WHATEVER YOU WANT

-- general
lvim.log.level = "warn"
lvim.format_on_save = false
lvim.colorscheme = "tokyonight"
-- to disable icons and use a minimalist setup, uncomment the following
-- lvim.use_icons = false

-- keymappings [view all the defaults by pressing <leader>Lk]
lvim.leader = "space"
-- add your own keymapping
lvim.keys.normal_mode["<C-s>"] = ":w<cr>"
lvim.keys.normal_mode["<C-t>"] = ":tabe<cr>"
lvim.keys.normal_mode["<leader>o"] = ":ClangdSwitchSourceHeader<cr>"
lvim.keys.normal_mode["L"] = ":bnext<cr>"
lvim.keys.normal_mode["H"] = ":bprev<cr>"
lvim.keys.normal_mode["<Leader>bo"] = ':%bd!|e #|bd #|normal`"<CR>'

lvim.keys.normal_mode["<F8>"] = ":Gitsigns stage_hunk<cr>"
lvim.keys.normal_mode["<F9>"] = ":Gitsigns next_hunk<cr>"
lvim.keys.normal_mode["<F10>"] = ":Gitsigns prev_hunk<cr>"
lvim.keys.normal_mode["<F11>"] = ":Gitsigns reset_hunk<cr>"
lvim.keys.normal_mode["<F12>"] = ":Gitsigns preview_hunk<cr>"

-- unmap a default keymapping
-- vim.keymap.del("n", "<C-Up>")
-- override a default keymapping
-- lvim.keys.normal_mode["<C-q>"] = ":q<cr>" -- or vim.keymap.set("n", "<C-q>", ":q<cr>" )

vim.opt.relativenumber = true
vim.opt.wrap = true
vim.opt.tabstop = 4
vim.opt.sts = 4
vim.opt.sw = 4

-- Change Telescope navigation to use j and k for navigation and n and p for history in both input and normal mode.
-- we use protected-mode (pcall) just in case the plugin wasn't loaded yet.
-- local _, actions = pcall(require, "telescope.actions")
-- lvim.builtin.telescope.defaults.mappings = {
--   -- for input mode
--   i = {
--     ["<C-j>"] = actions.move_selection_next,
--     ["<C-k>"] = actions.move_selection_previous,
--     ["<C-n>"] = actions.cycle_history_next,
--     ["<C-p>"] = actions.cycle_history_prev,
--   },
--   -- for normal mode
--   n = {
--     ["<C-j>"] = actions.move_selection_next,
--     ["<C-k>"] = actions.move_selection_previous,
--   },
-- }

-- Use which-key to add extra bindings with the leader-key prefix
-- lvim.builtin.which_key.mappings["P"] = { "<cmd>Telescope projects<CR>", "Projects" }
-- lvim.builtin.which_key.mappings["t"] = {
--   name = "+Trouble",
--   r = { "<cmd>Trouble lsp_references<cr>", "References" },
--   f = { "<cmd>Trouble lsp_definitions<cr>", "Definitions" },
--   d = { "<cmd>Trouble document_diagnostics<cr>", "Diagnostics" },
--   q = { "<cmd>Trouble quickfix<cr>", "QuickFix" },
--   l = { "<cmd>Trouble loclist<cr>", "LocationList" },
--   w = { "<cmd>Trouble workspace_diagnostics<cr>", "Wordspace Diagnostics" },
-- }

-- TODO: User Config for predefined plugins
-- After changing plugin config exit and reopen LunarVim, Run :PackerInstall :PackerCompile
lvim.builtin.alpha.active = true
lvim.builtin.alpha.mode = "dashboard"
lvim.builtin.terminal.active = true
lvim.builtin.nvimtree.setup.view.side = "left"
lvim.builtin.nvimtree.setup.renderer.icons.show.git = false
lvim.builtin.dap.active = true;

-- if you don't want all the parsers change this to a table of the ones you want
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

-- generic LSP settings

-- -- make sure server will always be installed even if the server is in skipped_servers list
-- lvim.lsp.installer.setup.ensure_installed = {
--     "sumeko_lua",
--     "jsonls",
-- }
-- -- change UI setting of `LspInstallInfo`
-- -- see <https://github.com/williamboman/nvim-lsp-installer#default-configuration>
-- lvim.lsp.installer.setup.ui.check_outdated_servers_on_open = false
-- lvim.lsp.installer.setup.ui.border = "rounded"
-- lvim.lsp.installer.setup.ui.keymaps = {
--     uninstall_server = "d",
--     toggle_server_expand = "o",
-- }

-- ---@usage disable automatic installation of servers
-- lvim.lsp.automatic_servers_installation = false

-- ---configure a server manually. !!Requires `:LvimCacheReset` to take effect!!
-- ---see the full default list `:lua print(vim.inspect(lvim.lsp.automatic_configuration.skipped_servers))`
-- vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "pyright" })
-- local opts = {} -- check the lspconfig documentation for a list of all possible options
-- require("lvim.lsp.manager").setup("pyright", opts)

-- ---remove a server from the skipped list, e.g. eslint, or emmet_ls. !!Requires `:LvimCacheReset` to take effect!!
-- ---`:LvimInfo` lists which server(s) are skipped for the current filetype
-- vim.tbl_map(function(server)
--   return server ~= "emmet_ls"
-- end, lvim.lsp.automatic_configuration.skipped_servers)

-- -- you can set a custom on_attach function that will be used for all the language servers
-- -- See <https://github.com/neovim/nvim-lspconfig#keybindings-and-completion>
-- lvim.lsp.on_attach_callback = function(client, bufnr)
--   local function buf_set_option(...)
--     vim.api.nvim_buf_set_option(bufnr, ...)
--   end
--   --Enable completion triggered by <c-x><c-o>
--   buf_set_option("omnifunc", "v:lua.vim.lsp.omnifunc")
-- end

-- set a formatter, this will override the language server formatting capabilities (if it exists)
local formatters = require "lvim.lsp.null-ls.formatters"
formatters.setup {
    { command = "black", filetypes = { "python" } },
    --   {
    --     -- each formatter accepts a list of options identical to https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md#Configuration
    --     command = "prettier",
    --     ---@usage arguments to pass to the formatter
    --     -- these cannot contain whitespaces, options such as `--line-width 80` become either `{'--line-width', '80'}` or `{'--line-width=80'}`
    --     extra_args = { "--print-with", "100" },
    --     ---@usage specify which filetypes to enable. By default a providers will attach to all the filetypes it supports.
    --     filetypes = { "typescript", "typescriptreact" },
    --   },
}

-- -- set additional linters
-- local linters = require "lvim.lsp.null-ls.linters"
-- linters.setup {
--     { command = "flake8", filetypes = { "python" } },
    -- {
    --   -- each linter accepts a list of options identical to https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md#Configuration
    --   command = "shellcheck",
    --   ---@usage arguments to pass to the formatter
    --   -- these cannot contain whitespaces, options such as `--line-width 80` become either `{'--line-width', '80'}` or `{'--line-width=80'}`
    --   extra_args = { "--severity", "warning" },
    -- },
    -- {
    --   command = "codespell",
    --   ---@usage specify which filetypes to enable. By default a providers will attach to all the filetypes it supports.
    --   filetypes = { "javascript", "python" },
    -- },
-- }

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
        miDebuggerServerAddress = '10.200.18.72:1234',
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


-- Extra git keymaps
-- require('gitsigns').setup {
--     on_attach = function(bufnr)
--         local gs = package.loaded.gitsigns

--         local function map(mode, l, r, opts)
--           opts = opts or {}
--           opts.buffer = bufnr
--           vim.keymap.set(mode, l, r, opts)
--         end

--         -- Extra actions
--         map('n', '<F9>', gs.prev_hunk)
--         map('n', '<F10>', gs.next_hunk)
--         map('n', '<F11>', gs.preview_hunk)
--         map('n', '<F12>', gs.preview_hunk)
--     end
-- }

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
                    side = 'right',
                    width = 20, -- set to 1 for a pure scrollbar :)
                    winblend = 15,
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
            vim.keymap.set('n', '<leader>Dd', function() require("duck").hatch() end, {})
            vim.keymap.set('n', '<leader>Dm', function() require("duck").hatch("🐕", 0.5) end, {})
            vim.keymap.set('n', '<leader>Dk', function() require("duck").cook() end, {})
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
    }
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

-- lvim.builtin.which_key.mappings["G"] = {
--     name = "Debugprint",
--     p = { "Add simple debug print" },
--     v = { "Add variable debug print" },
--     d = { "Delete all prints" },
-- }

-- Plugin keymaps
-- debugprint
-- vim.keymap.set("n", "<Leader>Gp", function()
--     require('debugprint').debugprint()
-- end)
-- vim.keymap.set("n", "<Leader>GP", function()
--     require('debugprint').debugprint({above = true})
-- end)
-- vim.keymap.set("n", "<Leader>Gv", function()
--     require('debugprint').debugprint({variable = true})
-- end)
-- vim.keymap.set("n", "<Leader>GV", function()
--     require('debugprint').debugprint({above = true, variable = true})
-- end)
-- vim.keymap.set("v", "<Leader>Gv", function()
--     require('debugprint').debugprint({variable = true})
-- end)
-- vim.keymap.set("v", "<Leader>GV", function()
--     require('debugprint').debugprint({above = true, variable = true})
-- end)
-- vim.keymap.set("n", "<Leader>Gd", function()
--     require('debugprint').deleteprints()
-- end)

-- Autocommands (https://neovim.io/doc/user/autocmd.html)
-- vim.api.nvim_create_autocmd("BufEnter", {
--   pattern = { "*.json", "*.jsonc" },
--   -- enable wrap mode for json files only
--   command = "setlocal wrap",
-- })
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "zsh",
--   callback = function()
--     -- let treesitter use bash highlight for zsh files as well
--     require("nvim-treesitter.highlight").attach(0, "bash")
--   end,
-- })
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
