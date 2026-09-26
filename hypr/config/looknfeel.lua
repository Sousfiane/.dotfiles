hl.config({
	general = {

		gaps_in = 4,
		gaps_out = 8,

		border_size = 2,
		col = { active_border = "rgba(c4a7e7e6)", inactive_border = "rgba(6e6a86b3)" },

		layout = "scrolling",
	},

	decoration = {
		rounding = 6,
		rounding_power = 2,

		active_opacity = 1.0,
		inactive_opacity = 1.0,

		shadow = {
			enabled = true,
			range = 2,
			render_power = 3,
			color = "rgba(1a1a1aee)",
		},

		blur = {
			enabled = true,
			size = 6,
			passes = 3,

			vibrancy = 0.1696,
		},
	},

	animations = {
		enabled = true,
	},

	misc = {
		force_default_wallpaper = 0,
		disable_hyprland_logo = true,
		render_unfocused_fps = 60,
	},

	xwayland = {
		force_zero_scaling = true,
		use_nearest_neighbor = false,
	},

	ecosystem = {
		no_update_news = true,
	},
})

hl.curve("easeInOutQuart", { type = "bezier", points = { { 0.77, 0 }, { 0.175, 1 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 2, bezier = "easeInOutQuart", style = "slidefade" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 2, bezier = "easeInOutQuart", style = "popin" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 4, bezier = "easeInOutQuart", style = "popin" })
hl.animation({ leaf = "fade", enabled = true, speed = 2, bezier = "easeInOutQuart" })
hl.animation({ leaf = "border", enabled = false })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2, bezier = "easeInOutQuart", style = "slidefade 10%" })
