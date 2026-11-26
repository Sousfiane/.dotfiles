-- Shows what a key prefix leads to, after a pause.

vim.pack.add({ "https://github.com/folke/which-key.nvim" })

local wk = require("which-key")
wk.setup({
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

vim.keymap.set("n", "<leader>?", function()
	wk.show({ global = false })
end, { desc = "Buffer local keymaps (which-key)" })
