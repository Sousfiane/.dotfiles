return {
	"nvimtools/none-ls.nvim",
	dependencies = { "williamboman/mason.nvim", "jay-babu/mason-null-ls.nvim" },
	config = function()
		require("mason").setup()

		local null_ls = require("null-ls")
		null_ls.setup({
			sources = {
				null_ls.builtins.formatting.stylua,
				null_ls.builtins.formatting.prettier,
			},
		})

		require("mason-null-ls").setup({
			ensure_installed = nil,
			automatic_installation = true,
		})

		vim.keymap.set("n", "<leader>f", vim.lsp.buf.format, {})
	end,
}
