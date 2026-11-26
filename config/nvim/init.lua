-- Neovim's entry point. Plugins come from vim.pack, Neovim's own plugin manager: each file in lua/plugins
-- adds what it needs (vim.pack.add) and sets it up, and nvim-pack-lock.json pins their versions.
-- :PackUpdate updates them, :PackClean removes the ones no file adds any more (lua/config/pack.lua).

require("config.options")
require("config.autocmds")
require("config.pack")

-- in this order: the colour scheme first, completion before the LSP (which asks it for capabilities)
for _, name in ipairs({
	"colorscheme",
	"treesitter",
	"lualine",
	"noice",
	"which-key",
	"neo-tree",
	"undotree",
	"telescope",
	"gitsigns",
	"completion",
	"lsp",
	"format",
	"sidekick",
}) do
	require("plugins." .. name)
end

-- every keymap, last: the plugins it maps are set up by now
require("config.keymaps")
