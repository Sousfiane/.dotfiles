-- Commands around vim.pack. Plugins live in ~/.local/share/nvim/site/pack/core/opt, their versions in
-- nvim-pack-lock.json (in the repo: commit it after an update).

-- downloads what's new and shows it; :write in that tab applies it, :quit drops it
vim.api.nvim_create_user_command("PackUpdate", function(args)
	vim.pack.update(#args.fargs > 0 and args.fargs or nil)
end, {
	nargs = "*",
	desc = "Update plugins (all, or the ones named)",
	complete = function()
		return vim.tbl_map(function(p)
			return p.spec.name
		end, vim.pack.get())
	end,
})

-- deletes the plugins on disk that no file adds any more
vim.api.nvim_create_user_command("PackClean", function()
	local unused = vim.iter(vim.pack.get())
		:filter(function(p)
			return not p.active
		end)
		:map(function(p)
			return p.spec.name
		end)
		:totable()
	if #unused == 0 then
		vim.notify("No unused plugins")
		return
	end
	if vim.fn.confirm("Delete " .. table.concat(unused, ", ") .. "?", "&Yes\n&No", 2) == 1 then
		vim.pack.del(unused)
	end
end, { desc = "Delete plugins no longer added" })
