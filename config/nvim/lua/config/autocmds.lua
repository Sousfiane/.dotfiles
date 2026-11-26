-- Autocommands that need no plugin. The LSP's are in lsp.lua.

local group = vim.api.nvim_create_augroup("config", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
	group = group,
	desc = "Flash what was yanked",
	callback = function()
		vim.hl.on_yank({ higroup = "Search", timeout = 200 })
	end,
})

-- the diagnostics under the cursor, when it rests. Not over another float (a hover, a signature), which it
-- would cover
vim.api.nvim_create_autocmd("CursorHold", {
	group = group,
	desc = "Show the diagnostics under the cursor",
	callback = function()
		for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
			if vim.api.nvim_win_get_config(win).relative ~= "" then
				return
			end
		end
		vim.diagnostic.open_float({ scope = "cursor", focusable = false })
	end,
})
