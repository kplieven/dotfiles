local deps = require('mini.deps')

deps.add({ source = 'ibhagwan/fzf-lua' })

require('fzf-lua').setup({
  winopts = {
    height = 0.85,
    width = 0.80,
    border = "rounded",
    preview = {
      border = "rounded",
      layout = "flex",
    },
  },
  fzf_opts = {
    ["--ansi"] = true,
    ["--info"] = "inline-right",
    ["--layout"] = "reverse",
    ["--highlight-line"] = true,
  },
  grep = {
    rg_opts = "--column --line-number --no-heading --color=always --smart-case -e",
    actions = {
      ["ctrl-g"] = { require("fzf-lua").actions.grep_lgrep }
    },
  },
  files = {
    file_icons = "mini",
  },
  defaults = {
    file_icons = "mini",
  },
})

local fzf = require('fzf-lua')

vim.keymap.set('n', '<leader>f',  fzf.files,       { desc = 'Find files' })
vim.keymap.set('n', '<leader>st', fzf.live_grep,   { desc = 'Live grep' })
vim.keymap.set('n', '<leader>sr', fzf.resume,      { desc = 'Resume previous search' })
vim.keymap.set('n', '<leader>sw', fzf.grep_cword,  { desc = 'Search current word' })
vim.keymap.set('n', '<leader>sb', fzf.buffers,     { desc = 'Search open buffers' })

local wk = require('which-key')
wk.add({
    { '<leader>s', group = 'Search' },
})
