local theme = require("config.theme")

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
		class = "^(localsend|FloatingTerm|nm-connection-editor|org.gnome.NautilusPreviewer|hyprland-share-picker)$",
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

-- Programs on specific workspaces
hl.window_rule({
	name = "kitty-on-ws1",
	match = { class = "^(kitty)$" },
	workspace = "1",
})

hl.window_rule({
	name = "zen-on-ws2",
	match = { class = "^(zen)$" },
	workspace = "2",
})

hl.window_rule({
	name = "discord-on-ws3",
	match = { class = "^(vesktop)$" },
	workspace = "3",
})

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

hl.layer_rule({
	name = "noanim-layers",
	match = { class = "hyprshot" },
	no_anim = true,
})

hl.window_rule({
	-- hyprbars has no inactive title color: titles are subtle (plugins.lua), the focused one gets Theme.text
	name = "titlebar-focused-text",
	match = { focus = true },
	["hyprbars:title_color"] = theme.rgb("text"),
})
