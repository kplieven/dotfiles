return {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },
    config = function()
        require("nvim-tree").setup {}
        vim.keymap.set('n', '<Leader>e', require'nvim-tree.api'.tree.toggle, { desc = "Toggle [E]xplorer" })
    end,
}
