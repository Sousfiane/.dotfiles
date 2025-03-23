return {
	"rcarriga/nvim-notify",
	config = function()
		require("notify").setup({
			stages = "fade_in_slide_out",
			timeout = 3000,
			background_colour = "#000000",
			render = "default",
			max_width = nil,
			max_height = nil,
		})
		vim.notify = require("notify")
	end,
}
