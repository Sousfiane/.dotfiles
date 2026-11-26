-- Fuzzy finding: files, grep, LSP lists, and every vim.ui.select (code actions...) as a dropdown.
-- Its keymaps are in lua/config/keymaps.lua. On master: the 0.1.x tags look for nvim-treesitter's old API, which the main branch doesn't have.

vim.pack.add({
	"https://github.com/nvim-lua/plenary.nvim",
	"https://github.com/nvim-telescope/telescope-ui-select.nvim",
	{ src = "https://github.com/nvim-telescope/telescope.nvim", version = "master" },
})

local telescope = require("telescope")
telescope.setup({
	extensions = {
		["ui-select"] = require("telescope.themes").get_dropdown({}),
	},
})
telescope.load_extension("ui-select")
