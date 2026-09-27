return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	lazy = false,
	config = function()
		local ts = require("nvim-treesitter")
		ts.setup({
			install_dir = vim.fn.stdpath("data") .. "/site",
		})

		-- Pre-install primary parsers
		ts.install({ "vimdoc", "javascript", "typescript", "c", "lua", "rust", "bash" })

		local ignore = { noice = true, notify = true, lspinfo = true, lazy = true, checkhealth = true, [""] = true }

		vim.api.nvim_create_autocmd("FileType", {
			callback = function(args)
				local buf = args.buf
				local ft = vim.bo[buf].filetype
				if ignore[ft] then
					return
				end

				local lang = vim.treesitter.language.get_lang(ft) or ft

				-- 1. Try starting highlighters immediately
				local ok = pcall(vim.treesitter.start, buf, lang)

				-- 2. If missing, run TSInstall command asynchronously and attach on completion
				if not ok then
					vim.system({ "nvim", "--headless", "-c", "TSInstall " .. lang, "-c", "q" }, {}, function(obj)
						if obj.code == 0 then
							vim.schedule(function()
								if vim.api.nvim_buf_is_valid(buf) then
									pcall(vim.treesitter.start, buf, lang)
								end
							end)
						end
					end)
				end
			end,
		})
	end,
}
