return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	lazy = false,
	main = "nvim-treesitter.configs",
	opts = {
		ensure_installed = { "vimdoc", "javascript", "typescript", "c", "lua", "rust" },
		sync_install = false,
		auto_install = true,
		highlight = {
			enable = true,
			additional_vim_regex_highlighting = false,
		},
	},
}
