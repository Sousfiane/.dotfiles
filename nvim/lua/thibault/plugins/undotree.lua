return {
	"mbbill/undotree",
	config = function()
		vim.keymap.set("n", "<leader>u", function()
			require("dapui").close()
			vim.cmd(":Neotree filesystem close")
			vim.cmd.UndotreeToggle()
		end)

		vim.g.undotree_SplitWidth = 40
	end,
}
