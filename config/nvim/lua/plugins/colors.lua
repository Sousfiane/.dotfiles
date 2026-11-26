-- The rose-pine plugin with the palette from ~/.config/theme/theme.json and the palette it names
-- (config/theme in the dotfiles), which quickshell, Hyprland, kitty and tmux read too. Without those
-- files, the plugin's own Rosé Pine.
local function read(path)
	return vim.json.decode(table.concat(vim.fn.readfile(vim.fn.expand(path)), "\n"))
end

-- the plugin variant to use and its colours, or nil
local function theme_palette()
	local ok, palette = pcall(function()
		local theme = read("~/.config/theme/theme.json")
		-- the current palette: the state file (out of the repo, written by `theme`), or the default
		local state = vim.fn.expand("~/.local/state/theme/palette")
		local name = vim.fn.filereadable(state) == 1 and vim.trim(vim.fn.readfile(state, "", 1)[1] or "") or ""
		return read("~/.config/theme/palettes/" .. (name ~= "" and name or theme.palette) .. ".json")
	end)
	if not ok then
		vim.notify("theme.json: " .. tostring(palette), vim.log.levels.WARN)
		return nil
	end
	local c = palette.colors
	-- the plugin's highlight rules differ only between dark and light (dawn)
	local variant = palette.dark and "main" or "dawn"
	return variant,
		{
			base = c.base,
			surface = c.surface,
			overlay = c.overlay,
			muted = c.muted,
			subtle = c.subtle,
			text = c.text,
			love = c.love,
			gold = c.gold,
			rose = c.rose,
			pine = c.pine,
			foam = c.foam,
			iris = c.iris,
			highlight_low = c.highlightLow,
			highlight_med = c.highlightMed,
			highlight_high = c.highlightHigh,
		}
end

-- the plugin's options, from the theme files as they are now
local function make_opts()
	local variant, colors = theme_palette()
	return {
		variant = variant or "main",
		palette = variant and { [variant] = colors } or {},
		styles = {
			bold = false,
			italic = true,
			transparency = true,
		},
		highlight_groups = {
			ColorColumn = { bg = "rose" },
			CursorColumn = { bg = "highlight_med" },
			CursorLine = { bg = "foam", blend = 10 },
			-- no background, like the terminal's (kitty shows it see-through); part of the colour scheme so a
			-- reload (kitty changing colours with the theme) keeps it
			StatusLine = { fg = "love", bg = "NONE" },
			Search = { bg = "gold" },
		},
	}
end

local function apply(opts)
	vim.o.background = opts.variant == "dawn" and "light" or "dark"
	require("rose-pine").setup(opts)
	vim.cmd("colorscheme rose-pine")
end

-- Follows theme changes live: watches the folders theme.json and the palettes really live in (the repo,
-- since editors write through the links) and the one with the current palette's name (written by
-- `theme`), and applies again shortly after one of them changes.
local function follow_theme()
	local timer = assert(vim.uv.new_timer())
	local function changed(err, name)
		if err or not (name and (name:match("%.json$") or name == "palette")) then return end
		timer:stop()
		timer:start(200, 0, vim.schedule_wrap(function()
			apply(make_opts())
		end))
	end
	local theme = vim.fn.expand("~/.config/theme")
	local settings = vim.uv.fs_realpath(theme .. "/theme.json")
	local palettes = vim.uv.fs_realpath(theme .. "/palettes")
	local state = vim.fn.expand("~/.local/state/theme")
	vim.fn.mkdir(state, "p")
	for _, dir in ipairs({ settings and vim.fs.dirname(settings), palettes, state }) do
		local watcher = vim.uv.new_fs_event()
		if dir and watcher then watcher:start(dir, {}, changed) end
	end
end

return {
	"rose-pine/neovim",
	name = "rose-pine",
	opts = make_opts,
	config = function(_, opts)
		apply(opts)
		follow_theme()
	end,
}
