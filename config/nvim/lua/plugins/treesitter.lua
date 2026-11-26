-- nvim-treesitter's main branch only installs parsers and queries: highlighting is Neovim's own
-- (vim.treesitter.start), and there's no auto_install any more. This brings it back: opening a file whose
-- language has no parser yet installs it in the background, then turns highlighting on in every buffer
-- that was waiting for it.
return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	lazy = false,
	config = function()
		local ts = require("nvim-treesitter")
		ts.setup({
			install_dir = vim.fn.stdpath("data") .. "/site",
		})

		local function set(list)
			local s = {}
			for _, v in ipairs(list) do
				s[v] = true
			end
			return s
		end

		local available = set(ts.get_available()) -- languages nvim-treesitter can install
		local installed = set(ts.get_installed("parsers"))
		local waiting = {} -- language being installed -> buffers to start once it's there
		local failed = {} -- not retried until the next start (the error was already shown)

		-- installs lang once, however many buffers ask for it meanwhile, then starts it in those buffers
		local function ensure(lang, buf)
			if installed[lang] or failed[lang] or not available[lang] then
				return
			end
			if waiting[lang] then
				table.insert(waiting[lang], buf)
				return
			end
			waiting[lang] = { buf }
			ts.install(lang):await(function(err, ok)
				vim.schedule(function()
					local bufs = waiting[lang]
					waiting[lang] = nil
					if err or not ok then
						failed[lang] = true
						return
					end
					installed[lang] = true
					for _, b in ipairs(bufs) do
						if vim.api.nvim_buf_is_valid(b) and vim.treesitter.language.get_lang(vim.bo[b].filetype) == lang then
							pcall(vim.treesitter.start, b, lang)
						end
					end
				end)
			end)
		end

		-- always wanted, even before a file of that language is opened
		for _, lang in ipairs({ "vimdoc", "javascript", "typescript", "c", "lua", "rust", "bash" }) do
			ensure(lang)
		end

		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("treesitter_start", { clear = true }),
			callback = function(args)
				local lang = vim.treesitter.language.get_lang(args.match)
				-- filetypes with no parser (noice, lazy, neo-tree...) aren't in `available`: nothing happens
				if lang and not pcall(vim.treesitter.start, args.buf, lang) then
					ensure(lang, args.buf)
				end
			end,
		})
	end,
}
