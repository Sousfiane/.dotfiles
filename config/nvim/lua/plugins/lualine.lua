-- The status line. lualine sets itself up again on every colour scheme change, so it follows `theme` too.

vim.pack.add({
	"https://github.com/nvim-tree/nvim-web-devicons",
	"https://github.com/nvim-lualine/lualine.nvim",
})

require("lualine").setup({
	options = {
		theme = "rose-pine",
		globalstatus = true,
	},
	sections = {
		-- the diff from gitsigns, so it changes with it (staging a hunk, an edit) and not on lualine's own timer
		lualine_b = {
			"branch",
			{
				"diff",
				source = function()
					local s = vim.b.gitsigns_status_dict
					return s and { added = s.added, modified = s.changed, removed = s.removed }
				end,
			},
			"diagnostics",
		},
	},
	extensions = { "mason", "neo-tree", "quickfix" },
})
