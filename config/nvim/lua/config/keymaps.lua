-- Every keymap, in one place. Loaded last (init.lua), once the plugins are set up, so the plugin sections
-- can require them. Keys that only work inside a plugin's own window stay in that plugin's setup: the
-- completion menu's in completion.lua, the picker's and the tree's are the plugins' defaults.
-- Removing a plugin: remove its section here too.

local map = vim.keymap.set

-- ---------- editing ----------

-- moving around
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })
map("n", "J", "mzJ`z", { desc = "Join lines without moving cursor" })
map("n", "<C-d>", "<C-d>zz", { desc = "Page down and center cursor" })
map("n", "<C-u>", "<C-u>zz", { desc = "Page up and center cursor" })
map("n", "n", "nzzzv", { desc = "Next search result and center" })
map("n", "N", "Nzzzv", { desc = "Previous search result and center" })

-- clipboard and deleting
map("x", "<leader>p", [["_dP]], { desc = "Paste over selection without yanking" })
map({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to system clipboard" })
map("n", "<leader>Y", [["+Y]], { desc = "Yank line to system clipboard" })
map({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete without yanking" })

-- windows
map("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to window below" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to window above" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- commands
map("n", "<C-n>", "<cmd>silent !tmux neww tmux-sessionizer<CR>", { desc = "Open tmux-sessionizer" })
map(
	"n",
	"<leader>s",
	[[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
	{ desc = "Search and replace word under cursor" }
)
map("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true, desc = "Make current file executable" })

-- ---------- diagnostics: <leader>e, as <leader>d is the delete above (]d and [d do the same as en/ep) ----------

map("n", "<leader>en", function()
	vim.diagnostic.jump({ count = 1 })
end, { desc = "Next diagnostic" })
map("n", "<leader>ep", function()
	vim.diagnostic.jump({ count = -1 })
end, { desc = "Previous diagnostic" })
map("n", "<leader>el", function()
	require("telescope.builtin").diagnostics({ bufnr = 0 })
end, { desc = "List buffer diagnostics" })

-- ---------- telescope: finding, <leader>p ----------

local builtin = require("telescope.builtin")
map("n", "<leader>pf", builtin.find_files, { desc = "Find files" })
map("n", "<C-p>", builtin.git_files, { desc = "Find git files" })
map("n", "<leader>pWs", function()
	builtin.grep_string({ search = vim.fn.expand("<cWORD>") })
end, { desc = "Search WORD under cursor" })
map("n", "<leader>ps", function()
	builtin.grep_string({ search = vim.fn.input("Grep > ") })
end, { desc = "Grep" })

-- ---------- neo-tree and undotree: they take the same place, opening one closes the other ----------

map("n", "<leader>pv", function()
	vim.cmd.UndotreeHide()
	vim.cmd("Neotree filesystem reveal left toggle")
end, { desc = "Toggle file tree" })
map("n", "<leader>u", function()
	vim.cmd("Neotree filesystem close")
	vim.cmd.UndotreeToggle()
end, { desc = "Toggle undo tree" })

-- ---------- LSP: <leader>g, only in buffers with a server ----------

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("lsp-keymaps", { clear = true }),
	callback = function(event)
		local function lsp_map(lhs, rhs, desc)
			map("n", lhs, rhs, { buffer = event.buf, desc = desc })
		end
		lsp_map("K", vim.lsp.buf.hover, "Hover documentation")
		lsp_map("<leader>ca", vim.lsp.buf.code_action, "Code action")
		lsp_map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
		lsp_map("<leader>gd", builtin.lsp_definitions, "Go to definition")
		lsp_map("<leader>gr", builtin.lsp_references, "References")
		lsp_map("<leader>gi", builtin.lsp_implementations, "Implementations")
		lsp_map("<leader>gs", builtin.lsp_document_symbols, "Document symbols")
		lsp_map("<leader>ws", builtin.lsp_dynamic_workspace_symbols, "Workspace symbols")
	end,
})

-- ---------- gitsigns: hunks, <leader>G ----------

local gs = require("gitsigns")
map("n", "<leader>Gh", gs.preview_hunk, { desc = "Preview hunk" })
map("n", "<leader>Gn", function()
	gs.nav_hunk("next")
end, { desc = "Next hunk" })
map("n", "<leader>Gp", function()
	gs.nav_hunk("prev")
end, { desc = "Previous hunk" })
-- stage_hunk on a staged hunk unstages it: what undo_stage_hunk did, before gitsigns dropped it
map("n", "<leader>Gs", gs.stage_hunk, { desc = "Stage / unstage hunk" })
map("n", "<leader>Gu", gs.stage_hunk, { desc = "Unstage hunk" })
map("n", "<leader>Gr", gs.reset_hunk, { desc = "Reset hunk" })
map("n", "<leader>GR", gs.reset_buffer, { desc = "Reset buffer" })
map("n", "<leader>Gb", gs.blame_line, { desc = "Blame line" })
map("n", "<leader>Gd", gs.diffthis, { desc = "Diff file" })

-- ---------- sidekick: AI CLIs, <leader>a ----------

local cli = require("sidekick.cli")
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

-- ---------- which-key ----------

map("n", "<leader>?", function()
	require("which-key").show({ global = false })
end, { desc = "Buffer local keymaps (which-key)" })
