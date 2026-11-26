-- The file tree, on the left. <leader>pv toggles it (and hides the undo tree, which takes the same place).

vim.pack.add({
	"https://github.com/nvim-lua/plenary.nvim",
	"https://github.com/nvim-tree/nvim-web-devicons",
	"https://github.com/MunifTanjim/nui.nvim",
	{ src = "https://github.com/nvim-neo-tree/neo-tree.nvim", version = "v3.x" },
})

require("neo-tree").setup({
	close_if_last_window = true,
	filesystem = {
		use_libuv_file_watcher = true,
		follow_current_file = {
			enabled = true,
		},
	},
})

vim.keymap.set("n", "<leader>pv", function()
	vim.cmd.UndotreeHide()
	vim.cmd("Neotree filesystem reveal left toggle")
end, { desc = "Toggle file tree" })

-- git marks in the tree follow what gitsigns sees (a hunk staged, a file saved). neo-tree waits a little
-- and runs one `git status` for a burst of these
vim.api.nvim_create_autocmd("User", {
	group = vim.api.nvim_create_augroup("neo-tree-gitsigns", { clear = true }),
	pattern = "GitSignsUpdate",
	callback = function()
		local events = require("neo-tree.events")
		events.fire_event(events.GIT_EVENT)
	end,
})
