-- Language servers: Mason installs them, mason-lspconfig enables the installed ones, nvim-lspconfig has
-- their settings. Diagnostics, and the keymaps and word highlights a buffer gets once a server attaches.

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

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
	callback = function(event)
		local buf = event.buf
		local client = assert(vim.lsp.get_client_by_id(event.data.client_id))
		local builtin = require("telescope.builtin")

		local function map(lhs, rhs, desc)
			vim.keymap.set("n", lhs, rhs, { buffer = buf, desc = desc })
		end
		map("K", vim.lsp.buf.hover, "Hover documentation")
		map("<leader>ca", vim.lsp.buf.code_action, "Code action")
		map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
		map("<leader>gd", builtin.lsp_definitions, "Go to definition")
		map("<leader>gr", builtin.lsp_references, "References")
		map("<leader>gi", builtin.lsp_implementations, "Implementations")
		map("<leader>gs", builtin.lsp_document_symbols, "Document symbols")
		map("<leader>ws", builtin.lsp_dynamic_workspace_symbols, "Workspace symbols")

		-- the other uses of the word under the cursor, while it rests there
		if client:supports_method("textDocument/documentHighlight", buf) then
			local highlight = vim.api.nvim_create_augroup("lsp-highlight-" .. buf, { clear = true })
			vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
				group = highlight,
				buffer = buf,
				callback = vim.lsp.buf.document_highlight,
			})
			vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
				group = highlight,
				buffer = buf,
				callback = vim.lsp.buf.clear_references,
			})
			vim.api.nvim_create_autocmd("LspDetach", {
				group = highlight,
				buffer = buf,
				callback = function()
					vim.lsp.buf.clear_references()
					vim.api.nvim_del_augroup_by_id(highlight)
				end,
			})
		end
	end,
})
