return {
	"hrsh7th/nvim-cmp",
	dependencies = {
		"hrsh7th/cmp-path",
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-nvim-lsp",
		"L3MON4D3/LuaSnip",
		"saadparwaiz1/cmp_luasnip",
		"rafamadriz/friendly-snippets",
	},
	opts = {
		snippet = {
			expand = function(args)
				require("luasnip").lsp_expand(args.body)
			end,
		},
		window = {
			completion = require("cmp").config.window.bordered(),
			documentation = require("cmp").config.window.bordered(),
		},
		mapping = require("cmp").mapping.preset.insert({
			["<C-b>"] = require("cmp").mapping.scroll_docs(-4),
			["<C-f>"] = require("cmp").mapping.scroll_docs(4),
			["<C-Space>"] = require("cmp").mapping.complete(),
			["<C-e>"] = require("cmp").mapping.abort(),
			["<CR>"] = require("cmp").mapping.confirm({ select = true }),
		}),
		sources = require("cmp").config.sources({
			{ name = "nvim_lsp" },
			{ name = "luasnip" },
			{ name = "buffer" },
			{ name = "buffer" },
			{ name = "path" },
		}),
	},
	init = function()
		require("luasnip.loaders.from_vscode").lazy_load() -- Load VSCode-style snippets
	end,
}
