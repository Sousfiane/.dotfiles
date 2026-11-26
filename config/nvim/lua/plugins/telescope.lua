-- Fuzzy finding: files, grep, LSP lists, and every vim.ui.select (code actions...) as a dropdown.
-- On master: the 0.1.x tags look for nvim-treesitter's old API, which the main branch doesn't have.

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

local builtin = require("telescope.builtin")
local map = vim.keymap.set

map("n", "<leader>pf", builtin.find_files, { desc = "Find files" })
map("n", "<C-p>", builtin.git_files, { desc = "Find git files" })
map("n", "<leader>pWs", function()
	builtin.grep_string({ search = vim.fn.expand("<cWORD>") })
end, { desc = "Search WORD under cursor" })
map("n", "<leader>ps", function()
	builtin.grep_string({ search = vim.fn.input("Grep > ") })
end, { desc = "Grep" })
map("n", "<leader>el", function()
	builtin.diagnostics({ bufnr = 0 })
end, { desc = "List buffer diagnostics" })
