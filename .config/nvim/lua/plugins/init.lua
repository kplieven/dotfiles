local path_package = vim.fn.stdpath('data') .. '/site/'
local mini_path = path_package .. 'pack/deps/start/mini.deps'

if not vim.loop.fs_stat(mini_path) then
    vim.cmd('echo "Installing `mini.deps`" | redraw')
    local clone_cmd = { 'git', 'clone', '--filter=blob:none', 'https://github.com/echasnovski/mini.deps', mini_path }
    vim.fn.system(clone_cmd)
    vim.cmd('packadd mini.deps | helptags ALL')
end

require('mini.deps').setup({ path = { package = path_package } })

-- Load plugin configurations
require("plugins.which-key")
require("plugins.copilot")
require("plugins.completion")
require("plugins.lsp")
require("plugins.colorscheme")
require("plugins.codesnap")
require("plugins.neoscroll")
require("plugins.alpha")
require("plugins.mini-icons")
require("plugins.mini-files")
require("plugins.mini-comment")
require("plugins.mini-pick")
require("plugins.mini-tabline")
require("plugins.mini-pairs")
require("plugins.mini-surround")
require("plugins.mini-cursorword")
require("plugins.mini-hipatterns")
require("plugins.mini-indentscope")
require("plugins.mini-map")
require("plugins.mini-notify")
require("plugins.mini-statusline")
require("plugins.mini-trailspace")
require("plugins.mini-diff")
