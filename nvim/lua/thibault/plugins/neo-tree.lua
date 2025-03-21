return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	config = function()
		vim.keymap.set("n", "<leader>pv",
        function ()
            vim.cmd('UndotreeHide')
            require("dapui").close()
            vim.cmd(":Neotree filesystem reveal left toggle")
        end, {})
	end,
}
