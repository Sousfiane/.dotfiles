-- Messages, the command line and LSP docs in floating windows.

vim.pack.add({
	"https://github.com/MunifTanjim/nui.nvim",
	"https://github.com/folke/noice.nvim",
})

require("noice").setup({
	cmdline = {
		view = "cmdline",
	},
	lsp = {
		override = {
			["vim.lsp.util.convert_input_to_markdown_lines"] = true,
			["vim.lsp.util.stylize_markdown"] = true,
			["cmp.entry.get_documentation"] = true,
		},
	},
	presets = {
		lsp_doc_border = true,
	},
})
