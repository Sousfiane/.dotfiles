-- AI CLIs (Claude...) in a split or a tmux pane, with the file, selection or line sent to them. Its keymaps
-- (<leader>a, <C-.>) are in lua/config/keymaps.lua.

vim.pack.add({ "https://github.com/folke/sidekick.nvim" })

require("sidekick").setup({
	cli = {
		mux = { backend = "tmux", enabled = true },
	},
})
