-- Language servers: Mason installs them, mason-lspconfig enables the installed ones, nvim-lspconfig has
-- their settings, and diagnostics. What a buffer gets once a server attaches is elsewhere: the word
-- highlights in lua/config/autocmds.lua, the keymaps in lua/config/keymaps.lua.

vim.pack.add({
	"https://github.com/mason-org/mason.nvim",
	"https://github.com/mason-org/mason-lspconfig.nvim",
	"https://github.com/neovim/nvim-lspconfig",
})

-- every server gets the capabilities nvim-cmp adds (snippets, more completion details)
vim.lsp.config("*", { capabilities = require("cmp_nvim_lsp").default_capabilities() })
vim.lsp.config("lua_ls", {
	settings = {
		Lua = {
			diagnostics = { globals = { "vim" } },
		},
	},
})

require("mason").setup()
require("mason-lspconfig").setup({
	ensure_installed = { "lua_ls", "ts_ls", "html", "cssls", "clangd", "eslint" },
	-- stylua is in Mason for conform (format.lua); as a language server too, it formatted Lua a second time
	automatic_enable = { exclude = { "stylua" } },
})

vim.diagnostic.config({
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "",
			[vim.diagnostic.severity.WARN] = "",
			[vim.diagnostic.severity.INFO] = "",
			[vim.diagnostic.severity.HINT] = "",
		},
	},
	float = { header = "", prefix = "", suffix = "" },
	update_in_insert = true,
	-- jumping to a diagnostic (]d, [d, <leader>en, <leader>ep) shows it
	jump = {
		on_jump = function(_, bufnr)
			vim.diagnostic.open_float({ bufnr = bufnr, scope = "cursor", focus = false })
		end,
	},
})
