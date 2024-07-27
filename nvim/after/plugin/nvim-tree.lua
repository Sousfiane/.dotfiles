require("nvim-tree").setup()
vim.keymap.set("n", "<leader>pv", function() return require("nvim-tree.api").tree.toggle({ focus = true, find_file = true }) end)
