require("nvim-tree").setup()
local api = require("nvim-tree.api")

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.keymap.set("n", "<leader>pv", function() api.tree.toggle({ focus = true, find_file = true }) end)
