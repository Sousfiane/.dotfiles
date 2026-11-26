-- Git changes in the sign column. Its keymaps (<leader>G) are in lua/config/keymaps.lua.

vim.pack.add({ "https://github.com/lewis6991/gitsigns.nvim" })

require("gitsigns").setup({
	preview_config = {
		border = "rounded",
		style = "minimal",
		relative = "cursor",
		row = 0,
		col = 1,
	},
})
