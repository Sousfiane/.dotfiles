return {
	"lewis6991/gitsigns.nvim",
	config = function()
		require("gitsigns").setup({
			preview_config = {
				border = "rounded",
				style = "minimal",
				relative = "cursor",
				row = 0,
				col = 1,
			},
		})

		vim.keymap.set("n", "<leader>Gp", ":Gitsigns preview_hunk<CR>", { desc = "Preview Git hunk" })
		vim.keymap.set("n", "<leader>Gn", ":Gitsigns next_hunk<CR>", { desc = "Go to next hunk" })
		vim.keymap.set("n", "<leader>Gp", ":Gitsigns prev_hunk<CR>", { desc = "Go to previous hunk" })
		vim.keymap.set("n", "<leader>Gs", ":Gitsigns stage_hunk<CR>", { desc = "Stage hunk" })
		vim.keymap.set("n", "<leader>Gu", ":Gitsigns undo_stage_hunk<CR>", { desc = "Undo stage hunk" })
		vim.keymap.set("n", "<leader>Gr", ":Gitsigns reset_hunk<CR>", { desc = "Reset hunk" })
		vim.keymap.set("n", "<leader>GR", ":Gitsigns reset_buffer<CR>", { desc = "Reset buffer" })
		vim.keymap.set("n", "<leader>Gb", ":Gitsigns blame_line<CR>", { desc = "Git blame line" })
		vim.keymap.set("n", "<leader>Gd", ":Gitsigns diffthis<CR>", { desc = "Show diff" })
	end,
}
