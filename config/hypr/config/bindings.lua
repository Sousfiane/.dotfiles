-- Mod keys
local mod = "SUPER"
local shift = "SHIFT"
local ctrl = "CTRL"
local alt = "ALT"

-- Quickshell commands (menus, volume, media, OSD): `qs ipc call <target> <function>`
local qs = "qs ipc call "

--------------------------------------------------
-- 🪟 Window management
--------------------------------------------------

hl.bind(mod .. " + Q", hl.dsp.window.close(), { description = "Close active window" })

hl.bind(mod .. " + F", hl.dsp.window.fullscreen(), { description = "Toggle fullscreen" })

hl.bind(mod .. " + " .. shift .. " + F", require("config.floating").toggle, { description = "Toggle floating and resize window" })

hl.bind(mod .. " + P", require("config.popout").toggle, { description = "Toggle picture-in-picture / popup mode" })

hl.bind(mod .. " + T", require("config.monitors").toggle_tv, { description = "Toggle the TV (left of the main screen)" })

--------------------------------------------------
-- 🚀 Menus
--------------------------------------------------

-- each opens or closes a Quickshell panel: `qs ipc call <target> toggle`
local menus = {
	{ key = "Space", target = "launcher", description = "Menu: Apps" },
	{ key = "W", target = "wallpaper", description = "Menu: Wallpapers" },
	{ key = "V", target = "clipboard", description = "Menu: Clipboard" },
	{ key = "M", target = "mixer", description = "Menu: Mixer" },
	{ key = "U", target = "updates", description = "Menu: Updates" },
	{ key = "N", target = "notifs", description = "Menu: Notifications" },
	{ key = "D", target = "dotfiles", description = "Menu: Dotfiles" },
	{ key = "S", target = "screenshot", description = "Menu: Screenshot" },
	{ key = "Escape", target = "power", description = "Menu: Power" },
	-- SUPER + / : on the French layout / is SHIFT + :, so SHIFT is part of the bind
	{ key = shift .. " + slash", target = "keybinds", description = "Menu: Keybinds" },
	{ key = alt .. " + Space", target = "hub", description = "Menu: Hub" },
}

for _, m in ipairs(menus) do
	hl.bind(mod .. " + " .. m.key, hl.dsp.exec_cmd(qs .. m.target .. " toggle"), { description = m.description })
end

--------------------------------------------------
-- 🔌 Session
--------------------------------------------------

hl.bind(mod .. " + Backspace", hl.dsp.exec_cmd(qs .. "lock lock"), { description = "Lock screen" })

-- Mission Control: every workspace's strip, live (macOS's Ctrl + Up)
hl.bind(mod .. " + Up", hl.dsp.exec_cmd(qs .. "overview toggle"), { description = "Overview (Mission Control)" })

-- the app switcher (macOS's Cmd + Tab, with ALT: SUPER + Tab is the workspaces). ALT + ² (the key above Tab,
-- by keycode) goes through the windows of the app in front, as Cmd + ` does. Letting go of ALT goes to the
-- chosen one: passed on to the apps too (non_consuming), and a no-op when the switcher isn't open
hl.bind(alt .. " + Tab", hl.dsp.exec_cmd(qs .. "switcher next apps"), { description = "App switcher: next app" })
hl.bind(alt .. " + " .. shift .. " + Tab", hl.dsp.exec_cmd(qs .. "switcher prev apps"), { description = "App switcher: previous app" })
hl.bind(alt .. " + code:49", hl.dsp.exec_cmd(qs .. "switcher next windows"), { description = "App switcher: next window of the app" })
hl.bind(
	alt .. " + " .. shift .. " + code:49",
	hl.dsp.exec_cmd(qs .. "switcher prev windows"),
	{ description = "App switcher: previous window of the app" }
)
hl.bind(alt .. " + Alt_L", hl.dsp.exec_cmd(qs .. "switcher commit"), { release = true, non_consuming = true, description = "App switcher: go (ALT let go)" })

hl.bind(
	mod .. " + " .. shift .. " + Backspace",
	hl.dsp.exec_cmd("uwsm stop"),
	{ description = "Stop session / Logout" }
)

--------------------------------------------------
-- 🖥️ Applications
--------------------------------------------------

-- the terminal always opens a new one, here; the others go to the app when it's open (apps.lua)
local apps = require("config.apps")

hl.bind(mod .. " + Return", hl.dsp.exec_cmd("uwsm-app -- xdg-terminal-exec"), { description = "Open terminal" })

hl.bind(
	mod .. " + " .. shift .. " + Return",
	hl.dsp.exec_cmd("uwsm-app -- xdg-terminal-exec --app-id=FloatingTerm"),
	{ description = "Open floating terminal" }
)

hl.bind(
	mod .. " + E",
	apps.focus_or_open("org.gnome.Nautilus", "uwsm-app -- nautilus"),
	{ description = "Go to or open file manager (Nautilus)" }
)

hl.bind(
	mod .. " + B",
	apps.focus_or_open("zen", "uwsm-app -- zen-browser"),
	{ description = "Go to or open browser (Zen)" }
)

hl.bind(
	mod .. " + C",
	apps.focus_or_open("vesktop", "uwsm-app -- vesktop"),
	{ description = "Go to or open chat (Vesktop)" }
)

--------------------------------------------------
-- 🔧 Utilities
--------------------------------------------------

-- Quickshell is a user service (install/units/quickshell.service): restarted through it, so it stays one that
-- comes back after a crash (a `qs` killed and started by hand would run outside it)
hl.bind(
	mod .. " + " .. shift .. " + R",
	hl.dsp.exec_cmd("systemctl --user restart quickshell"),
	{ description = "Restart Quickshell" }
)

--------------------------------------------------
-- 🧭 Focus (vim-style)
--------------------------------------------------

hl.bind(mod .. " + H", hl.dsp.layout("focus l"), { description = "Focus window left" })
hl.bind(mod .. " + J", hl.dsp.layout("focus d"), { description = "Focus window down" })
hl.bind(mod .. " + K", hl.dsp.layout("focus u"), { description = "Focus window up" })
hl.bind(mod .. " + L", hl.dsp.layout("focus r"), { description = "Focus window right" })

--------------------------------------------------
-- 🔄 Swap windows
--------------------------------------------------

hl.bind(mod .. " + " .. shift .. " + H", hl.dsp.layout("swapcol l"), { description = "Swap column left" })
hl.bind(mod .. " + " .. shift .. " + L", hl.dsp.layout("swapcol r"), { description = "Swap column right" })

--------------------------------------------------
-- 🖱️ The strip (scrolling layout), as on a trackpad
--------------------------------------------------

-- the wheel goes along the strip, column by column (down is right); with SHIFT, workspace by workspace
hl.bind(mod .. " + mouse_down", hl.dsp.layout("focus r"), { description = "Focus column right (wheel)" })
hl.bind(mod .. " + mouse_up", hl.dsp.layout("focus l"), { description = "Focus column left (wheel)" })
hl.bind(
	mod .. " + " .. shift .. " + mouse_down",
	hl.dsp.focus({ workspace = "m+1" }),
	{ description = "Next workspace (wheel)" }
)
hl.bind(
	mod .. " + " .. shift .. " + mouse_up",
	hl.dsp.focus({ workspace = "m-1" }),
	{ description = "Previous workspace (wheel)" }
)

-- the column's width, through the layout's widths (⅓, ½, ⅔, full: scrolling:explicit_column_widths), as
-- macOS tiles a window to halves and thirds
-- (CTRL: SUPER + ALT + a letter is OBS's)
hl.bind(mod .. " + R", hl.dsp.layout("colresize +conf"), { description = "Column wider (⅓ ½ ⅔ full)" })
hl.bind(mod .. " + " .. ctrl .. " + R", hl.dsp.layout("colresize -conf"), { description = "Column narrower" })
hl.bind(mod .. " + " .. ctrl .. " + mouse_up", hl.dsp.layout("colresize +conf"), { description = "Column wider (wheel)" })
hl.bind(
	mod .. " + " .. ctrl .. " + mouse_down",
	hl.dsp.layout("colresize -conf"),
	{ description = "Column narrower (wheel)" }
)

--------------------------------------------------
-- 🔀 Move workspace between monitors
--------------------------------------------------

hl.bind(
	mod .. " + " .. ctrl .. " + H",
	hl.dsp.workspace.move({ monitor = "l" }),
	{ description = "Move workspace to left monitor" }
)

hl.bind(
	mod .. " + " .. ctrl .. " + L",
	hl.dsp.workspace.move({ monitor = "r" }),
	{ description = "Move workspace to right monitor" }
)

--------------------------------------------------
-- 📑 Workspaces (1–9)
--------------------------------------------------

local codes = { 10, 11, 12, 13, 14, 15, 16, 17, 18 }

for i, code in ipairs(codes) do
	hl.bind(mod .. " + code:" .. code, hl.dsp.focus({ workspace = i }), { description = "Switch to workspace " .. i })
	hl.bind(
		mod .. " + " .. shift .. " + code:" .. code,
		hl.dsp.window.move({ workspace = i }),
		{ description = "Move window to workspace " .. i }
	)
end

--------------------------------------------------
-- 🔁 Workspace cycling
--------------------------------------------------

hl.bind(mod .. " + TAB", hl.dsp.focus({ workspace = "m+1" }), { description = "Next workspace" })

hl.bind(mod .. " + " .. shift .. " + TAB", hl.dsp.focus({ workspace = "m-1" }), { description = "Previous workspace" })

hl.bind(
	mod .. " + " .. ctrl .. " + TAB",
	hl.dsp.focus({ workspace = "previous" }),
	{ description = "Toggle previous workspace" }
)

hl.bind(
	mod .. " + " .. shift .. " + N",
	hl.dsp.focus({ workspace = "empty" }),
	{ description = "Go to first empty workspace" }
)

--------------------------------------------------
-- 🖱️ Mouse actions
--------------------------------------------------

hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Drag window" })

--------------------------------------------------
-- 🔊 Volume (Quickshell shows the OSD)
--------------------------------------------------

hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd(qs .. "audio up"),
	{ locked = true, repeating = true, description = "Raise volume" }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd(qs .. "audio down"),
	{ locked = true, repeating = true, description = "Lower volume" }
)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(qs .. "audio mute"), { locked = true, description = "Toggle audio mute" })
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd(qs .. "audio micMute"),
	{ locked = true, description = "Toggle microphone mute" }
)

--------------------------------------------------
-- 🎵 Media keys
--------------------------------------------------

hl.bind("XF86AudioNext", hl.dsp.exec_cmd(qs .. "media next"), { locked = true, description = "Next media track" })
hl.bind(
	"XF86AudioPrev",
	hl.dsp.exec_cmd(qs .. "media previous"),
	{ locked = true, description = "Previous media track" }
)
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd(qs .. "media toggle"), { locked = true, description = "Play/Pause media" })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd(qs .. "media toggle"), { locked = true, description = "Play/Pause media" })

--------------------------------------------------
-- 🔠 Caps Lock OSD
--------------------------------------------------

hl.bind("Caps_Lock", hl.dsp.exec_cmd(qs .. "osd caps"), { release = true, description = "Caps Lock OSD toggle" })

--------------------------------------------------
-- 🎬 OBS Studio (global shortcuts)
--------------------------------------------------

-- sent to OBS wherever the focus is, as SUPER + ALT + the same key (OBS's own shortcuts)
local obs = {
	{ key = "C", description = "OBS: Cam Scene" },
	{ key = "G", description = "OBS: Game Scene" },
	{ key = "B", description = "OBS: Browser Scene" },
	{ key = "P", description = "OBS: Screen Scene" },
	{ key = "T", description = "OBS: Term Scene" },
	{ key = "E", description = "OBS: Edit Scene" },
	{ key = "R", description = "OBS: Toggle Recording" },
	{ key = "S", description = "OBS: Toggle Streaming" },
	{ key = "M", description = "OBS: Mute Microphone" },
	{ key = "H", description = "OBS: Hide Cam + Mute" },
}

for _, o in ipairs(obs) do
	hl.bind(
		mod .. " + " .. alt .. " + " .. o.key,
		hl.dsp.send_shortcut({ mods = mod .. " + " .. alt, key = o.key, window = "class:^(obs)$" }),
		{ description = o.description }
	)
end
