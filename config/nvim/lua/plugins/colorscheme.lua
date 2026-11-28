-- The rose-pine plugin with the current palette, from the merged theme (~/.local/state/theme/current.json:
-- theme.json in config/theme, the fonts picked and the palette, put together by merge.sh), which quickshell,
-- Hyprland, kitty and tmux read too. Without it, the plugin's own Rosé Pine.
local state = vim.fn.expand("~/.local/state/theme")
local current = state .. "/current.json"

-- the plugin variant to use and its colours, or nil
local function theme_palette()
	local ok, palette = pcall(function()
		-- written first if it isn't there yet (a new machine)
		if vim.fn.filereadable(current) == 0 then
			vim.fn.system({ vim.fn.expand("~/.config/theme/merge.sh") })
		end
		return vim.json.decode(table.concat(vim.fn.readfile(current), "\n"))
	end)
	if not ok then
		vim.notify("theme: " .. tostring(palette), vim.log.levels.WARN)
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

-- Follows theme changes live: watches the merged theme's folder (merge.sh writes it whenever theme.json,
-- a palette, the current palette or the fonts change, as a new file renamed over the old), and applies
-- again shortly after current.json changes.
local function follow_theme()
	local timer = assert(vim.uv.new_timer())
	local function changed(err, name)
		if err or name ~= "current.json" then
			return
		end
		timer:stop()
		timer:start(
			200,
			0,
			vim.schedule_wrap(function()
				apply(make_opts())
			end)
		)
	end
	vim.fn.mkdir(state, "p")
	local watcher = vim.uv.new_fs_event()
	if watcher then
		watcher:start(state, {}, changed)
	end
end

vim.pack.add({ { src = "https://github.com/rose-pine/neovim", name = "rose-pine" } })

apply(make_opts())
follow_theme()
