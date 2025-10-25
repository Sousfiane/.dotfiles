return {
	"nvim-telescope/telescope.nvim",
	tag = "0.1.8",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope-ui-select.nvim",
	},
	opts = function()
		local telescope = require("telescope")
		telescope.load_extension("ui-select")
		return {
			extensions = {
				["ui-select"] = require("telescope.themes").get_dropdown({}),
			},
		}
	end,
}
