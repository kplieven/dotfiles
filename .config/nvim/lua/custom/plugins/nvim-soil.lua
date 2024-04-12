return {
    {
        'javiorfo/nvim-soil',
        lazy = true,
        ft = "plantuml",
        config = function()
            require 'soil'.setup {
                -- If you want to customize the image showed when running this plugin
                image = {
                    -- return "feh " .. img
                    -- return "xdg-open " .. img
                    execute_to_open = function(img)
                        return "feh " .. img
                    end
                }
            }
        end
    },

    -- Optional for puml syntax highlighting:
    { 'javiorfo/nvim-nyctophilia' }
}
