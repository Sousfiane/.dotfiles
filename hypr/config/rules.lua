local suppressMaximizeRule = hl.window_rule({
	-- Ignore maximize requests from all apps. You'll probably like this.
	name = "suppress-maximize-events",
	match = { class = ".*" },

	suppress_event = "maximize",
})
suppressMaximizeRule:set_enabled(true)

hl.window_rule({
	-- Fix some dragging issues with XWayland
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},

	no_focus = true,
})

hl.window_rule({
	name = "tag-floating-windows",
	match = {
		class = "^(localsend|blueberry.py|FloatingTerm|nm-connection-editor|org.gnome.NautilusPreviewer)$",
	},
	tag = "+floating-window",
})

hl.window_rule({
	name = "apply-floating-layout",
	match = {
		tag = "floating-window",
	},
	float = true,
	center = true,
	size = { 875, 600 },
})

-- Workspace 9 (TV mode)
hl.workspace_rule({
	workspace = "9",
	no_border = true,
	gaps_in = 0,
	gaps_out = 0,
	no_rounding = true,
})

-- Apply blur to common UI layers
hl.layer_rule({
	name = "blur-ui-layers",
	match = {
		class = "^(waybar|wofi|notifications|swayosd|quickshell)$",
	},
	blur = true,
})

-- Enable blur for waybar popups
hl.layer_rule({
	name = "waybar-blur-popups",
	match = {
		class = "^waybar$",
	},
	blur_popups = true,
})

-- Ignore fully transparent pixels when blurring
hl.layer_rule({
	name = "ignore-alpha-ui",
	match = {
		class = "^(notifications|waybar|wofi|swayosd)$",
	},
	ignore_alpha = 0,
})
