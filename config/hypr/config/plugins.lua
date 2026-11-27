local theme = require("config.theme")

if hl.plugin.csgo_vulkan_fix ~= nil then
	hl.plugin.csgo_vulkan_fix.vkfix_app({ app = "cs2", w = 1280, h = 960 })
	hl.config({
		plugin = {
			csgo_vulkan_fix = {
				fix_mouse = true,
			},
		},
	})
end

-- Title bar on top of every window (hyprpm enable hyprbars)
if hl.plugin.hyprbars ~= nil then
	hl.config({
		plugin = {
			hyprbars = {
				bar_height = 28,
				bar_color = theme.rgba("base", theme.opacity.terminal), -- same as kitty's background
				-- blur the bar ourselves: without it, the blurred background shows through as blocky garbage
				bar_blur = true,
				col = { text = theme.rgb("subtle") }, -- the focused window gets theme text (rules.lua)
				bar_text_font = theme.font.mono, -- same as kitty
				bar_text_size = 12,
				bar_text_weight = "semibold",
				bar_text_align = "center",
				bar_part_of_window = true,
				bar_precedence_over_border = true,
				bar_buttons_alignment = "right",
				bar_padding = 8,
				bar_button_padding = 8,
				inactive_button_color = theme.rgba("muted", 0.5), -- unfocused windows get grey dots, like macOS
				-- fullscreen hides this bar: the way back is the button in the quickshell bar (top edge)
				on_double_click = "hyprctl dispatch 'hl.dsp.window.fullscreen()'",
			},
		},
	})

	-- Buttons are placed from the edge inward: the first one added sits rightmost.
	-- Plain dots, no icons: red closes, gold fullscreens, blue toggles floating, iris toggles the popout.
	local dsp = function(d)
		return "hyprctl dispatch '" .. d .. "'"
	end
	hl.plugin.hyprbars.add_button({
		bg_color = theme.rgb("love"),
		fg_color = theme.rgb("base"),
		size = 12,
		icon = "",
		action = dsp("hl.dsp.window.close()"),
	})
	hl.plugin.hyprbars.add_button({
		bg_color = theme.rgb("gold"),
		fg_color = theme.rgb("base"),
		size = 12,
		icon = "",
		action = dsp("hl.dsp.window.fullscreen()"),
	})
	-- the same toggle as SUPER + SHIFT + F (floating.lua)
	hl.plugin.hyprbars.add_button({
		bg_color = theme.rgb("foam"),
		fg_color = theme.rgb("base"),
		size = 12,
		icon = "",
		action = dsp('require("config.floating").toggle'),
	})
	-- a lua function is a valid dispatch: the same toggle as SUPER + P (popout.lua)
	hl.plugin.hyprbars.add_button({
		bg_color = theme.rgb("iris"),
		fg_color = theme.rgb("base"),
		size = 12,
		icon = "",
		action = dsp('require("config.popout").toggle'),
	})
end
