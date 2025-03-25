return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	config = function()
		vim.g.loaded_netrw = 1
		vim.g.loaded_netrwPlugin = 1

		vim.keymap.set("n", "<leader>pv", function()
			vim.cmd("UndotreeHide")
			require("dapui").close()
			vim.cmd(":Neotree filesystem reveal left toggle")
		end, {})

		vim.api.nvim_create_autocmd("User", {
			pattern = "GitSignsUpdate",
			callback = function()
				require("neo-tree.sources.git_status").refresh()
			end,
		})

		require("neo-tree").setup({
			close_if_last_window = true,
			filesystem = {
				follow_current_file = {
					enabled = true,
				},
			},
			default_component_configs = {
				diagnostics = {
					symbols = {
						hint = "",
						info = "",
						warn = "",
						error = "",
					},
					enable = true,
					show_on_dirs = true,
					show_on_open_dirs = false,
				},
			},
		})
	end,
}
