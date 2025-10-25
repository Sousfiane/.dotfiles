return {
	"nvim-telescope/telescope.nvim",
	tag = "0.1.8",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope-ui-select.nvim",
	},
	opts = {
		extensions = {
			["ui-select"] = {},
		},
	},
	config = function(_, opts)
		local telescope = require("telescope")
		opts.extensions["ui-select"] = require("telescope.themes").get_dropdown({})
		telescope.setup(opts)
		telescope.load_extension("ui-select")
	end,
}
