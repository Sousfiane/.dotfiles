-- Formatting on save (conform), with the formatters below, or the language server's when none is listed.
-- mason-conform installs the listed formatters through Mason.

vim.pack.add({
	"https://github.com/mason-org/mason.nvim",
	"https://github.com/stevearc/conform.nvim",
	"https://github.com/zapling/mason-conform.nvim",
})

require("conform").setup({
	format_on_save = {
		timeout_ms = 500,
		lsp_format = "fallback",
	},
	formatters_by_ft = {
		lua = { "stylua" },
		c = { "clang-format" },
		javascript = { "prettierd", "prettier", stop_after_first = true },
		javascriptreact = { "prettierd", "prettier", stop_after_first = true },
	},
})
require("mason-conform").setup()
