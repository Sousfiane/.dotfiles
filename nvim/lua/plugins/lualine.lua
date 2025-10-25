return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	event = "ColorScheme",
	opts = {
		options = {
			theme = "rose-pine",
			globalstatus = true,
		},
		extensions = { "mason", "lazy", "neo-tree", "quickfix", "nvim-dap-ui" },
	},
	init = function()
		vim.g.loaded_netrw = 1
		vim.g.loaded_netrwPlugin = 1
	end,
}
