hl.config({
	general = {

		gaps_in = 4,
		gaps_out = 8,

		-- no borders: the hyprbars title bar shows focus (grey dots and a dim title when unfocused)
		border_size = 0,
		col = { active_border = "rgb(6e6a86)", inactive_border = "rgb(6e6a86)" },

		layout = "scrolling",

		allow_tearing = true,
	},

	decoration = {
		rounding = 6, -- keep in sync with Theme.radius (quickshell/config/Theme.qml)
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

-- Same curves and durations as quickshell/config/Motion.qml (speed is in tenths of a second):
--   move  (easeInOutQuart) A -> B, both on screen   2   = 200 ms
--   enter (easeOutExpo)    arriving                  2   = 200 ms
--   exit  (easeInQuart)    leaving                   1.5 = 150 ms
hl.curve("move", { type = "bezier", points = { { 0.77, 0 }, { 0.175, 1 } } })
hl.curve("enter", { type = "bezier", points = { { 0.16, 1 }, { 0.3, 1 } } })
hl.curve("exit", { type = "bezier", points = { { 0.7, 0 }, { 0.84, 0 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 2, bezier = "move", style = "slide" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 2, bezier = "enter", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.5, bezier = "exit", style = "slide" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 2, bezier = "enter", style = "popin" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "exit", style = "popin" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 2, bezier = "enter" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.5, bezier = "exit" })
hl.animation({ leaf = "fadeSwitch", enabled = true, speed = 1.2, bezier = "enter" })
hl.animation({ leaf = "border", enabled = false })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2, bezier = "move", style = "slidefade 10%" })
