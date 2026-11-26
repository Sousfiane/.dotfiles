-- Shows what a key prefix leads to, after a pause.

vim.pack.add({ "https://github.com/folke/which-key.nvim" })

-- the group names below label the prefixes set in lua/config/keymaps.lua
require("which-key").setup({
	win = { border = "rounded" },
	icons = { mappings = false },
	spec = {
		{ "<leader>a", group = "AI (sidekick)" },
		{ "<leader>e", group = "Diagnostics" },
		{ "<leader>g", group = "LSP" },
		{ "<leader>G", group = "Git" },
		{ "<leader>p", group = "Project", mode = "n" },
	},
})
