return {
	"neovim/nvim-lspconfig",
	dependencies = {
		"nvim-java/nvim-java",
		"williamboman/mason-lspconfig.nvim",
		"williamboman/mason.nvim",
		"stevearc/conform.nvim",
		"zapling/mason-conform.nvim",
		"hrsh7th/nvim-cmp", -- Added nvim-cmp dependency
		"hrsh7th/cmp-path",
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-nvim-lsp", -- LSP source for nvim-cmp
		"L3MON4D3/LuaSnip", -- LuaSnip for snippets
		"saadparwaiz1/cmp_luasnip", -- LuaSnip source for nvim-cmp
		"rafamadriz/friendly-snippets", -- Friendly snippets collection
	},
	config = function()
		------------------------------------------------------------
		-- Mason Setup
		------------------------------------------------------------
		require("mason").setup({
			ui = {
				border = "rounded",
			},
		})

		------------------------------------------------------------
		-- Java Setup
		------------------------------------------------------------
		require("java").setup()

		------------------------------------------------------------
		-- Mason LSP Config Setup
		------------------------------------------------------------
		require("mason-lspconfig").setup({
			ensure_installed = {
				"lua_ls",
				"ts_ls",
				"html",
				"cssls",
				"clangd",
				"eslint",
			},
		})

		------------------------------------------------------------
		-- Conform (Formatter) Setup
		------------------------------------------------------------
		require("conform").setup({
			format_on_save = {
				timeout_ms = 500,
				lsp_format = "fallback",
			},
			formatters_by_ft = {
				lua = { "stylua" },
				java = { "google-java-format" },
				c = { "clang-format" },
				javascript = { "prettierd", "prettier", stop_after_first = true },
				javascriptreact = { "prettierd", "prettier", stop_after_first = true },
			},
		})
		require("mason-conform").setup({})

		------------------------------------------------------------
		-- LSP Capabilities and Server Setup
		------------------------------------------------------------
		local capabilities = require("cmp_nvim_lsp").default_capabilities()

		vim.lsp.config("*", {
			capabilities = capabilities,
		})

		vim.lsp.config("ts_ls", {})
		vim.lsp.config("eslint", {})
		vim.lsp.config("html", {})
		vim.lsp.config("cssls", {})
		vim.lsp.config("jdtls", {})
		vim.lsp.config("clangd", {})
		vim.lsp.config("lua_ls", {
			settings = {
				Lua = {
					diagnostics = {
						globals = { "vim" },
					},
				},
			},
		})

		vim.lsp.enable({
			"ts_ls",
			"eslint",
			"html",
			"cssls",
			"jdtls",
			"clangd",
			"lua_ls",
		})

		vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
			border = "rounded",
		})

		------------------------------------------------------------
		-- LSP Key Mappings
		------------------------------------------------------------
		vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
		vim.keymap.set("n", "<leader>gd", require("telescope.builtin").lsp_definitions, {})
		vim.keymap.set("n", "<leader>gr", require("telescope.builtin").lsp_references, {})
		vim.keymap.set("n", "<leader>gi", require("telescope.builtin").lsp_implementations, {})
		vim.keymap.set("n", "<leader>ds", require("telescope.builtin").lsp_document_symbols, {})
		vim.keymap.set("n", "<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, {})
		vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {})
		vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, {})

		------------------------------------------------------------
		-- Diagnostic Configuration
		------------------------------------------------------------
		vim.diagnostic.config({
			signs = {
				text = {
					[vim.diagnostic.severity.ERROR] = "",
					[vim.diagnostic.severity.WARN] = "",
					[vim.diagnostic.severity.INFO] = "",
					[vim.diagnostic.severity.HINT] = "",
				},
			},
			underline = true, -- Enable underlines
			virtual_text = false,
			float = {
				border = "rounded",
				source = false,
				focusable = false,
				header = "",
				prefix = "",
			},
			update_in_insert = true, -- Show diagnostics (including underline) in insert mode
		})

		------------------------------------------------------------
		-- Diagnostic Key Mappings
		------------------------------------------------------------
		vim.keymap.set("n", "<leader>dn", vim.diagnostic.goto_next, { desc = "Go to next diagnostic" })
		vim.keymap.set("n", "<leader>dp", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic" })
		vim.keymap.set("n", "<leader>dl", function()
			require("telescope.builtin").diagnostics({ bufnr = 0 })
		end, { desc = "Show buffer diagnostics with Telescope" })
		vim.api.nvim_create_autocmd("CursorHold", {
			callback = function()
				vim.diagnostic.open_float(nil, { focusable = false })
			end,
		})

		------------------------------------------------------------
		-- highlights
		------------------------------------------------------------
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
			callback = function(event)
				local highlight_augroup = vim.api.nvim_create_augroup("lsp-highlight", { clear = false })
				vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
					buffer = event.buf,
					group = highlight_augroup,
					callback = vim.lsp.buf.document_highlight,
				})

				vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
					buffer = event.buf,
					group = highlight_augroup,
					callback = vim.lsp.buf.clear_references,
				})

				vim.api.nvim_create_autocmd("LspDetach", {
					group = vim.api.nvim_create_augroup("lsp-detach", { clear = true }),
					callback = function(event2)
						vim.lsp.buf.clear_references()
						vim.api.nvim_clear_autocmds({ group = "lsp-highlight", buffer = event2.buf })
					end,
				})
			end,
		})

		------------------------------------------------------------
		-- nvim-cmp Setup (Autocompletion)
		------------------------------------------------------------
		local cmp = require("cmp")
		require("luasnip.loaders.from_vscode").lazy_load() -- Load VSCode-style snippets

		cmp.setup({
			snippet = {
				expand = function(args)
					require("luasnip").lsp_expand(args.body)
				end,
			},
			window = {
				completion = cmp.config.window.bordered(),
				documentation = cmp.config.window.bordered(),
			},
			mapping = cmp.mapping.preset.insert({
				["<C-b>"] = cmp.mapping.scroll_docs(-4),
				["<C-f>"] = cmp.mapping.scroll_docs(4),
				["<C-Space>"] = cmp.mapping.complete(),
				["<C-e>"] = cmp.mapping.abort(),
				["<CR>"] = cmp.mapping.confirm({ select = true }),
			}),
			sources = cmp.config.sources({
				{ name = "nvim_lsp" }, -- Use LSP for completion
				{ name = "luasnip" }, -- Use LuaSnip for snippets
				{ name = "buffer" }, -- Use buffer source for completion
				{ name = "buffer" }, -- Words from the current buffer
				{ name = "path" }, -- File path completion
			}),
		})
	end,
}
