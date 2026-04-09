-- Build hooks (must be registered before any vim.pack.add calls)
vim.api.nvim_create_autocmd('PackChanged', {
    callback = function(ev)
        local name, kind = ev.data.spec.name, ev.data.kind
        if kind ~= 'install' and kind ~= 'update' then return end

        if name == 'nvim-treesitter' then
            vim.cmd('TSUpdate')
        elseif name == 'CopilotChat.nvim' then
            vim.system({ 'make', 'tiktoken' }, { cwd = ev.data.path })
        elseif name == 'codesnap.nvim' then
            vim.system({ 'make' }, { cwd = ev.data.path })
        end
    end,
})

vim.api.nvim_create_user_command('PackUpdate', function()
    require('vim.pack').update()
end, { desc = 'Update all plugins' })

-- Load plugin configurations
require("plugins.which-key")
require("plugins.copilot")
require("plugins.completion")
require("plugins.lsp")
require("plugins.treesitter")
require("plugins.colorscheme")
-- require("plugins.codesnap")
require("plugins.neoscroll")
require("plugins.alpha")
require("plugins.mini-icons")
require("plugins.mini-files")
require("plugins.mini-comment")
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
require("plugins.mini-git")
require("plugins.fzf")
