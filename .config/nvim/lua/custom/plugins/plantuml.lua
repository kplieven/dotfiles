return {
    'https://gitlab.com/itaranto/plantuml.nvim',
    version = '*',
    config = function()
        require('plantuml').setup(
            {
                renderer = {
                    type = 'image',
                    options = {
                        prog = 'feh',
                        dark_mode = true,
                    }
                },
                render_on_write = true,
            }
        )
    end,
}
