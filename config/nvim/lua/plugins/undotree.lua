-- The undo history as a tree. <leader>u toggles it (and closes the file tree, which takes the same place).

vim.g.undotree_SplitWidth = 40

vim.pack.add({ "https://github.com/mbbill/undotree" })

vim.keymap.set("n", "<leader>u", function()
	vim.cmd("Neotree filesystem close")
	vim.cmd.UndotreeToggle()
end, { desc = "Toggle undo tree" })
