local map = vim.keymap.set

-- =========================
-- Basic Movements
-- =========================
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })
map("n", "J", "mzJ`z", { desc = "Join lines without moving cursor" })
map("n", "<C-d>", "<C-d>zz", { desc = "Page down and center cursor" })
map("n", "<C-u>", "<C-u>zz", { desc = "Page up and center cursor" })
map("n", "n", "nzzzv", { desc = "Next search result and center" })
map("n", "N", "Nzzzv", { desc = "Previous search result and center" })

-- =========================
-- Clipboard / Delete
-- =========================
map("x", "<leader>p", [["_dP]], { desc = "Paste over selection without yanking" })
map({ "n", "v" }, "<leader>y", [["+y]], { desc = "Paste to system clipboard" })
map("n", "<leader>Y", [["+Y]], { desc = "Paste line to system clipboard" })
map({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete without yanking" })

-- =========================
-- Window Navigation
-- =========================
map("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to window below" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to window above" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- =========================
-- Commands
-- =========================
map(
	"n",
	"<C-n>",
	"<cmd>silent !tmux neww $DOTFILES/scripts/tmux-sessionizer.sh<CR>",
	{ desc = "Open tmux-sessionizer" }
)
map(
	"n",
	"<leader>s",
	[[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
	{ desc = "Search and replace word under cursor" }
)
map("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true, desc = "Make current file executable" })

-- =========================
-- Diagnostics
-- =========================
map("n", "<leader>dn", function()
	vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Go to next diagnostic" })

map("n", "<leader>dp", function()
	vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Go to previous diagnostic" })

map("n", "<leader>dl", function()
	local ok, telescope = pcall(require, "telescope.builtin")
	if ok then
		telescope.diagnostics({ bufnr = 0 })
	end
end, { desc = "Show buffer diagnostics with Telescope" })

-- =========================
-- LSP
-- =========================
map("n", "K", function()
	vim.lsp.buf.hover()
end, { desc = "Hover documentation" })

map("n", "<leader>ca", function()
	vim.lsp.buf.code_action()
end, { desc = "Code action" })

map("n", "<leader>rn", function()
	vim.lsp.buf.rename()
end, { desc = "Rename symbol" })

map("n", "<leader>gd", function()
	local ok, telescope = pcall(require, "telescope.builtin")
	if ok then
		telescope.lsp_definitions()
	end
end, { desc = "Go to definition" })

map("n", "<leader>gr", function()
	local ok, telescope = pcall(require, "telescope.builtin")
	if ok then
		telescope.lsp_references()
	end
end, { desc = "Show references" })

map("n", "<leader>gi", function()
	local ok, telescope = pcall(require, "telescope.builtin")
	if ok then
		telescope.lsp_implementations()
	end
end, { desc = "Go to implementations" })

map("n", "<leader>ds", function()
	local ok, telescope = pcall(require, "telescope.builtin")
	if ok then
		telescope.lsp_document_symbols()
	end
end, { desc = "Document symbols" })

map("n", "<leader>ws", function()
	local ok, telescope = pcall(require, "telescope.builtin")
	if ok then
		telescope.lsp_dynamic_workspace_symbols()
	end
end, { desc = "Workspace symbols" })

-- =========================
-- Neotree & Undotree
-- =========================
map("n", "<leader>pv", function()
	vim.cmd("UndotreeHide")
	vim.cmd(":Neotree filesystem reveal left toggle")
end, { desc = "Toggle Neotree" })

map("n", "<leader>u", function()
	vim.cmd(":Neotree filesystem close")
	vim.cmd.UndotreeToggle()
end, { desc = "Toggle Undotree" })

-- =========================
-- Telescope Searches
-- =========================
map("n", "<leader>pf", function()
	local ok, telescope = pcall(require, "telescope.builtin")
	if ok then
		telescope.find_files()
	end
end, { desc = "Find files" })

map("n", "<C-p>", function()
	local ok, telescope = pcall(require, "telescope.builtin")
	if ok then
		telescope.git_files()
	end
end, { desc = "Find git files" })

map("n", "<leader>pWs", function()
	local ok, telescope = pcall(require, "telescope.builtin")
	if ok then
		telescope.grep_string({ search = vim.fn.expand("<cWORD>") })
	end
end, { desc = "Search word under cursor" })

map("n", "<leader>ps", function()
	local ok, telescope = pcall(require, "telescope.builtin")
	if ok then
		telescope.grep_string({ search = vim.fn.input("Grep > ") })
	end
end, { desc = "Interactive grep search" })

-- =========================
-- Gitsigns
-- =========================
map("n", "<leader>Gh", ":Gitsigns preview_hunk<CR>", { desc = "Preview Git hunk" })
map("n", "<leader>Gn", ":Gitsigns next_hunk<CR>", { desc = "Go to next hunk" })
map("n", "<leader>Gp", ":Gitsigns prev_hunk<CR>", { desc = "Go to previous hunk" })
map("n", "<leader>Gs", ":Gitsigns stage_hunk<CR>", { desc = "Stage current hunk" })
map("n", "<leader>Gu", ":Gitsigns undo_stage_hunk<CR>", { desc = "Undo stage hunk" })
map("n", "<leader>Gr", ":Gitsigns reset_hunk<CR>", { desc = "Reset current hunk" })
map("n", "<leader>GR", ":Gitsigns reset_buffer<CR>", { desc = "Reset buffer hunks" })
map("n", "<leader>Gb", ":Gitsigns blame_line<CR>", { desc = "Git blame current line" })
map("n", "<leader>Gd", ":Gitsigns diffthis<CR>", { desc = "Show diff for current file" })
