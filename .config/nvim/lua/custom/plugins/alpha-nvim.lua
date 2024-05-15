return {
    "goolord/alpha-nvim",
    config = function()
        local alpha = require 'alpha'
        local dashboard = require 'alpha.themes.dashboard'

        dashboard.section.buttons.val = {
            dashboard.button("f", " " .. " Find file", ":Telescope find_files <CR>"),
            dashboard.button("n", " " .. " New file", ":ene <BAR> startinsert <CR>"),
            dashboard.button("r", " " .. " Recent files", ":Telescope oldfiles <CR>"),
            dashboard.button("g", " " .. " Find text", ":Telescope live_grep <CR>"),
            dashboard.button("c", " " .. " Config", ":e $MYVIMRC <CR>"),
            dashboard.button("l", "鈴" .. " Lazy", ":Lazy<CR>"),
            dashboard.button("q", " " .. " Quit", ":qa<CR>"),
        }

        dashboard.config.opts.noautocmd = true

        alpha.setup(dashboard.opts)
    end
}
