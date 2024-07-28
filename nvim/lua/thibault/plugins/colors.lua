return {
    'rose-pine/neovim',
    as = 'rose-pine',
    config = function()
        require('rose-pine').setup({
            variant = "main", -- auto, main, moon, or dawn
            dark_variant = "main", -- main, moon, or dawn
            dim_inactive_windows = false,
           --disable_background = true,
            extend_background_behind_borders = false,

            styles = {
                bold = false,
                italic = true,
                transparency = true,
            },

            groups = {
                --background = "NONE",
                border = "muted",
                link = "iris",
                panel = "surface",

                error = "love",
                hint = "iris",
                info = "foam",
                warn = "gold",

                git_add = "foam",
                git_change = "rose",
                git_delete = "love",
                git_dirty = "rose",
                git_ignore = "muted",
                git_merge = "iris",
                git_rename = "pine",
                git_stage = "iris",
                git_text = "rose",
                git_untracked = "subtle",

                headings = {
                    h1 = "iris",
                    h2 = "foam",
                    h3 = "rose",
                    h4 = "gold",
                    h5 = "pine",
                    h6 = "foam",
                },
            },

            highlight_groups = {

                ColorColumn = { bg = 'rose' },
                CursorColumn ={ bg = 'highlight_med'},

                CursorLine = { bg = 'foam', blend = 10 },
                StatusLine = { fg = 'love', bg = 'love', blend = 10 },

                Search = { bg = 'gold'},
            }
        })

        -- Set colorscheme after options
        vim.cmd('colorscheme rose-pine')
    end
}

