vim.pack.add({ 'https://github.com/kevalin/mermaid.nvim' })

vim.env.PATH = vim.fn.expand('~/.config/mermaid/bin') .. ':' .. vim.env.PATH

require('mermaid').setup({
    preview = {
        renderer = "beautiful-mermaid",
    }
})

-- Upstream passes SVG directly to Kitty, which only accepts raster images.
local render = require('mermaid.render')
local generate_svg = render.generate_svg
render.generate_svg = function(content, output_path)
    return generate_svg(content, output_path or (vim.fn.tempname() .. '.png'))
end

vim.api.nvim_create_autocmd('FileType', {
    pattern = 'mermaid',
    callback = function(args)
        local opts = { buffer = args.buf, desc = 'Mermaid' }
        vim.keymap.set('n', '<leader>mp', '<cmd>MermaidPreview<CR>', opts)
        vim.keymap.set('n', '<leader>mf', '<cmd>MermaidFormat<CR>', opts)
        vim.keymap.set('n', '<leader>mr', '<cmd>MermaidRender<CR>', opts)
        vim.keymap.set('n', '<leader>mx', '<cmd>MermaidPreviewStop<CR>', opts)
    end,
})
