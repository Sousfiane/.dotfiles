return {
    'mbbill/undotree',
    config = function()
        vim.keymap.set('n', '<leader>u', function()
            require("dapui").close()
            require("nvim-tree.api").tree.close()
            vim.cmd.UndotreeToggle()
        end)

        vim.g.undotree_SplitWidth = 40
    end
}
