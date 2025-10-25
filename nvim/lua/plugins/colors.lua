return {
	"rose-pine/neovim",
	name = "rose-pine",
	opts = {
		styles = {
			bold = false,
			italic = true,
			transparency = true,
		},
		highlight_groups = {
			ColorColumn = { bg = "rose" },
			CursorColumn = { bg = "highlight_med" },
			CursorLine = { bg = "foam", blend = 10 },
			StatusLine = { fg = "love", bg = "love", blend = 10 },
			Search = { bg = "gold" },
		},
	},
	config = function(_, opts)
		require("rose-pine").setup(opts)
		vim.cmd("colorscheme rose-pine")
		vim.cmd("hi statusline guibg=NONE")
	end,
}
