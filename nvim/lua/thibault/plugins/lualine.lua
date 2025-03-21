return {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
        require('lualine').setup({
            options = {
                theme = 'rose-pine',
                globalstatus = true,
            },
            extensions = { 'lazy', 'nvim-tree', 'quickfix', 'nvim-dap-ui' },
        })
    end
}

