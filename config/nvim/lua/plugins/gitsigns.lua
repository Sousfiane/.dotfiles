-- Git changes in the sign column, and hunks to preview, stage and reset under <leader>G.

vim.pack.add({ "https://github.com/lewis6991/gitsigns.nvim" })

local gs = require("gitsigns")
gs.setup({
	preview_config = {
		border = "rounded",
		style = "minimal",
		relative = "cursor",
		row = 0,
		col = 1,
	},
})

local map = vim.keymap.set
map("n", "<leader>Gh", gs.preview_hunk, { desc = "Preview hunk" })
map("n", "<leader>Gn", function()
	gs.nav_hunk("next")
end, { desc = "Next hunk" })
map("n", "<leader>Gp", function()
	gs.nav_hunk("prev")
end, { desc = "Previous hunk" })
-- stage_hunk on a staged hunk unstages it: what undo_stage_hunk did, before gitsigns dropped it
map("n", "<leader>Gs", gs.stage_hunk, { desc = "Stage / unstage hunk" })
map("n", "<leader>Gu", gs.stage_hunk, { desc = "Unstage hunk" })
map("n", "<leader>Gr", gs.reset_hunk, { desc = "Reset hunk" })
map("n", "<leader>GR", gs.reset_buffer, { desc = "Reset buffer" })
map("n", "<leader>Gb", gs.blame_line, { desc = "Blame line" })
map("n", "<leader>Gd", gs.diffthis, { desc = "Diff file" })
