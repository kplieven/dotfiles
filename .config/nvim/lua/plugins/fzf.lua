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
vim.keymap.set('n', '<leader>st', fzf.grep_project, { desc = 'Live Grep' })
