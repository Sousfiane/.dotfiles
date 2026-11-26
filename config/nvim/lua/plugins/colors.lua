-- The rose-pine plugin with the palette from ~/.config/theme/theme.json (config/theme/theme.json in the
-- dotfiles), which quickshell, Hyprland, kitty and tmux read too. Without that file, the plugin's own.
local function theme_palette()
	local ok, theme = pcall(function()
		return vim.json.decode(table.concat(vim.fn.readfile(vim.fn.expand("~/.config/theme/theme.json")), "\n"))
	end)
	if not ok then
		vim.notify("theme.json: " .. tostring(theme), vim.log.levels.WARN)
		return nil
	end
	local c = theme.colors
	return {
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
		return {
			palette = { main = theme_palette() },
			styles = {
				bold = false,
				italic = true,
				transparency = true,
			},
			highlight_groups = {
				ColorColumn = { bg = "rose" },
				CursorColumn = { bg = "highlight_med" },
				CursorLine = { bg = "foam", blend = 10 },
				StatusLine = { fg = "love", bg = "love", blend = 10 },
				Search = { bg = "gold" },
			},
		}
	end,
	config = function(_, opts)
		require("rose-pine").setup(opts)
		vim.cmd("colorscheme rose-pine")
		vim.cmd("hi statusline guibg=NONE")
	end,
}
