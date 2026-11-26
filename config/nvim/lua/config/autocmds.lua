-- Autocommands that need no plugin. The LSP keymaps are in keymaps.lua.

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

-- once a server attaches: the other uses of the word under the cursor, while it rests there
vim.api.nvim_create_autocmd("LspAttach", {
	group = group,
	desc = "Highlight the word under the cursor where a server can",
	callback = function(event)
		local buf = event.buf
		local client = assert(vim.lsp.get_client_by_id(event.data.client_id))

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
