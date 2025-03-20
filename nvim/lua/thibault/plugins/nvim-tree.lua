return {
    'nvim-tree/nvim-tree.lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
        require("nvim-tree").setup({
            view = {
                side = "left",
                adaptive_size = true,
                centralize_selection = true,
            },
            update_focused_file = {
                enable = true,
            },
            diagnostics = {
                enable = true,
                show_on_dirs = true,
            },
            actions = {
                change_dir = {
                    enable = false,
                },
            },
        })

        local api = require("nvim-tree.api")
        vim.g.loaded_netrw = 1
        vim.g.loaded_netrwPlugin = 1

        vim.keymap.set("n", "<leader>pv", function()
            require("dapui").close()
            vim.cmd('UndotreeHide')
            api.tree.toggle({ focus = true, find_file = true })
        end)
    end
}
