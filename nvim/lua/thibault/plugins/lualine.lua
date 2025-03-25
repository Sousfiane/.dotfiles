return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		require("lualine").setup({
			options = {
				theme = "rose-pine",
				globalstatus = true,
			},
			extensions = { "mason", "lazy", "neo-tree", "quickfix", "nvim-dap-ui" },
		})

		vim.api.nvim_create_autocmd("User", {
			pattern = "GitSignsUpdate",
			callback = function()
				require("lualine").refresh()
			end,
		})
	end,
}
