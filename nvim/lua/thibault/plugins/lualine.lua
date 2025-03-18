return {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
        require('lualine').setup({
            options = {
                theme = 'rose-pine',
                globalstatus = true,
            },
            sections = {
                lualine_a = { 'mode' },
                lualine_b = { 'branch' },
                lualine_c = {
                    { 'filename', file_status = true, path = 1 },
                    { 'diagnostics', sources = { 'nvim_lsp' }, sections = { 'error', 'warn' }, symbols = { error = ' ', warn = ' ' } }
                },
                lualine_x = {
                    'filetype',
                    { 'encoding', upper = true },
                    'progress',
                },
                lualine_y = { 'location' },
                lualine_z = { 'time' },
            },
            extensions = { 'fugitive', 'nvim-tree', 'quickfix' },
        })
    end
}

