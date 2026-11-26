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
		return read("~/.config/theme/palettes/" .. theme.palette .. ".json")
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

return {
	"rose-pine/neovim",
	name = "rose-pine",
	opts = function()
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
	end,
	config = function(_, opts)
		vim.o.background = opts.variant == "dawn" and "light" or "dark"
		require("rose-pine").setup(opts)
		vim.cmd("colorscheme rose-pine")
	end,
}
