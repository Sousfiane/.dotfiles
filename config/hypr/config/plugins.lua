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
				bar_height = 24,
				bar_color = "rgba(191724cc)", -- same as kitty: background #191724, background_opacity 0.8
				-- blur the bar ourselves: without it, the blurred background shows through as blocky garbage
				bar_blur = true,
				col = { text = "rgb(e0def4)" },
				bar_text_font = "JetBrainsMonoNL NF", -- same as kitty
				bar_text_size = 10,
				bar_text_weight = "semibold",
				bar_text_align = "center",
				bar_part_of_window = true,
				bar_precedence_over_border = true,
				bar_buttons_alignment = "right",
				bar_padding = 8,
				bar_button_padding = 6,
				-- fullscreen hides this bar: the way back is the button in the quickshell bar (top edge)
				on_double_click = "hyprctl dispatch 'hl.dsp.window.fullscreen()'",
			},
		},
	})

	-- Buttons are placed from the edge inward: the first one added sits rightmost.
	-- Plain dots, no icons: red closes, gold fullscreens, blue toggles floating.
	local dsp = function(d) return "hyprctl dispatch '" .. d .. "'" end
	hl.plugin.hyprbars.add_button({ bg_color = "rgb(eb6f92)", fg_color = "rgb(191724)", size = 10, icon = "", action = dsp("hl.dsp.window.close()") })
	hl.plugin.hyprbars.add_button({ bg_color = "rgb(f6c177)", fg_color = "rgb(191724)", size = 10, icon = "", action = dsp("hl.dsp.window.fullscreen()") })
	hl.plugin.hyprbars.add_button({ bg_color = "rgb(9ccfd8)", fg_color = "rgb(191724)", size = 10, icon = "", action = dsp("hl.dsp.window.float()") })
end
