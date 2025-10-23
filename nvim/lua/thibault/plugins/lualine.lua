return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	event = "ColorScheme",
	config = function()
		local theme = require("lualine.themes.rose-pine-alt")
		local new_bg = "#191724"

		for _, mode in pairs({ "normal", "insert", "visual", "replace", "command", "inactive" }) do
			for _, section in pairs({ "a", "b", "c" }) do
				if theme[mode] and theme[mode][section] then
					theme[mode][section].bg = new_bg
				end
			end
		end

		require("lualine").setup({
			options = {
				theme = theme,
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
