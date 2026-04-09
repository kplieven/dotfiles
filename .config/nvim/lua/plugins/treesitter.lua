local deps = require('mini.deps')

deps.add({
    source = 'nvim-treesitter/nvim-treesitter',
    hooks = {
        post_install = function() vim.cmd('TSUpdate') end,
        post_update  = function() vim.cmd('TSUpdate') end,
    },
})

require('nvim-treesitter').setup()

require('nvim-treesitter').install({
    'c', 'cpp', 'lua', 'python', 'rust',
    'vim', 'vimdoc', 'query',
    'bash', 'glsl', 'markdown', 'markdown_inline',
})

vim.api.nvim_create_autocmd('FileType', {
    callback = function(args)
        local max_filesize = 500 * 1024 -- 500 KB
        local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(args.buf))
        if ok and stats and stats.size > max_filesize then return end

        pcall(vim.treesitter.start)
        vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end,
})
