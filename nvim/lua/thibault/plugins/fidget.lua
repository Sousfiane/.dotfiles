return {
	"j-hui/fidget.nvim",
	config = function()
		require("fidget").setup({
			notification = { -- NOTE: you're missing this outer table
				window = {
					winblend = 0, -- NOTE: it's winblend, not blend
				},
			},
		})
	end,
}
