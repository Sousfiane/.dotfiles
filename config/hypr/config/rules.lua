local theme = require("config.theme")
local floating = require("config.floating")

hl.window_rule({
	-- Ignore maximize requests from all apps. You'll probably like this.
	name = "suppress-maximize-events",
	match = { class = ".*" },

	suppress_event = "maximize",
})

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
		class = "^(org.localsend.localsend_app|FloatingTerm|nm-connection-editor|org.gnome.NautilusPreviewer|hyprland-share-picker)$",
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
	size = { floating.size.x, floating.size.y }, -- the same as SUPER + SHIFT + F
})

-- Apps open where you are, next to the focused window in the strip, as macOS opens them on the current
-- Space: SUPER + B, C, E go to the app if it's open (bindings.lua), and ALT + Tab / Mission Control find the
-- rest; where an app lives is up to you (drag it in Mission Control). One exception: games, below.

-- Gaming on 4: the launchers and the games. Steam, its web helper and every Proton game (steam_app_*,
-- also what Heroic's umu runs give, steam_app_default); Heroic; gamescope. Games that pick their own
-- class (native ones, a game run in plain Wine: its .exe) are listed by name, so other Wine programs
-- stay where they open
hl.window_rule({
	name = "gaming-on-ws4",
	match = { class = "(?i)^(steam.*|heroic|gamescope|cs2)$" },
	workspace = "4",
})

-- OBS gets background rendering
hl.window_rule({
	name = "obs-render-unfocused",
	match = { class = "^(obs)$" },
	render_unfocused = true,
})

hl.window_rule({
	name = "cs2-tearing",
	match = { class = "^(cs2)$" },
	immediate = true,
})

hl.layer_rule({
	name = "quickshell-rules",
	match = {
		namespace = "^(quickshell|qs-.*)$",
	},
	no_anim = true,
	blur = true,
	ignore_alpha = 0.6,
	xray = true,
})

-- the screenshot panel's region selection (hyprshot runs slurp, whose layer is "selection"): there at once
hl.layer_rule({
	name = "noanim-layers",
	match = { namespace = "^(selection)$" },
	no_anim = true,
})

hl.window_rule({
	-- hyprbars has no inactive title color: titles are subtle (plugins.lua), the focused one gets Theme.text
	name = "titlebar-focused-text",
	match = { focus = true },
	["hyprbars:title_color"] = theme.rgb("text"),
})
