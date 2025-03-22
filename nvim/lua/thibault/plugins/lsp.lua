return {
	"neovim/nvim-lspconfig",
	dependencies = {
		"nvim-java/nvim-java",
		"williamboman/mason-lspconfig.nvim",
		"williamboman/mason.nvim",
		"stevearc/conform.nvim",
		"zapling/mason-conform.nvim",
		"hrsh7th/nvim-cmp", -- Added nvim-cmp dependency
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
				javascriptreact = { "prettierd", "prettier", stop_after_first = true }, -- Add this line for JSX files
			},
		})
		require("mason-conform").setup({})

		------------------------------------------------------------
		-- LSP Capabilities and Server Setup
		------------------------------------------------------------
		local capabilities = require("cmp_nvim_lsp").default_capabilities()
		local lspconfig = require("lspconfig")

		-- Typescript / JavaScript
		lspconfig.ts_ls.setup({
			capabilities = capabilities,
		})

		-- EsLint
		lspconfig.eslint.setup({
			capabilities = capabilities,
		})

		-- HTML
		lspconfig.html.setup({
			capabilities = capabilities,
		})

		-- CSS
		lspconfig.cssls.setup({
			capabilities = capabilities,
		})

		-- Lua
		lspconfig.lua_ls.setup({
			capabilities = capabilities,
			settings = {
				Lua = {
					diagnostics = {
						globals = { "vim" },
					},
				},
			},
		})

		-- Java (jdtls)
		lspconfig.jdtls.setup({
			capabilities = capabilities,
		})

		-- C/C++ (clangd)
		lspconfig.clangd.setup({
			capabilities = capabilities,
		})

		------------------------------------------------------------
		-- LSP Key Mappings
		------------------------------------------------------------
		vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
		vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, {})
		vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, {})
		vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {})

		------------------------------------------------------------
		-- Diagnostic Sign Setup
		------------------------------------------------------------
		local signs = {
			Error = " ",
			Warn = " ",
			Hint = " ",
			Info = " ",
		}

		for type, icon in pairs(signs) do
			local hl = "DiagnosticSign" .. type
			vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
		end

		------------------------------------------------------------
		-- Diagnostic Configuration
		------------------------------------------------------------
		vim.diagnostic.config({
			signs = true,
			underline = true,
			update_in_insert = false,
			float = {
				border = "rounded",
				source = "always",
			},
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
			}, {
				{ name = "buffer" }, -- Use buffer source for completion
			}),
		})
	end,
}
