-- AI CLIs (Claude...) in a split or a tmux pane, under <leader>a, with the file, selection or line sent to
-- them.

vim.pack.add({ "https://github.com/folke/sidekick.nvim" })

local sidekick = require("sidekick")
sidekick.setup({
	cli = {
		mux = { backend = "tmux", enabled = true },
	},
})

local cli = require("sidekick.cli")
local map = vim.keymap.set

map({ "n", "t", "i", "x" }, "<C-.>", cli.focus, { desc = "Sidekick focus" })
map("n", "<leader>aa", cli.toggle, { desc = "Toggle CLI" })
map("n", "<leader>ac", function()
	cli.toggle({ name = "claude", focus = true })
end, { desc = "Toggle Claude" })
map("n", "<leader>as", cli.select, { desc = "Select CLI" })
map("n", "<leader>ad", cli.close, { desc = "Detach a CLI session" })
map({ "n", "x" }, "<leader>at", function()
	cli.send({ msg = "{this}" })
end, { desc = "Send this" })
map("n", "<leader>af", function()
	cli.send({ msg = "{file}" })
end, { desc = "Send file" })
map("x", "<leader>av", function()
	cli.send({ msg = "{selection}" })
end, { desc = "Send selection" })
map({ "n", "x" }, "<leader>ap", cli.prompt, { desc = "Select prompt" })
