-- Mod keys
local mod = "SUPER"
local shift = "SHIFT"
local ctrl = "CTRL"
local alt = "ALT"

-- Quickshell commands (volume, media, OSD): `qs ipc call <target> <function>`
local qs = "qs ipc call "

--------------------------------------------------
-- 🪟 Window management
--------------------------------------------------

hl.bind(mod .. " + Q", hl.dsp.window.close(), { description = "Close active window" })

hl.bind(mod .. " + F", hl.dsp.window.fullscreen(), { description = "Toggle fullscreen" })

hl.bind(mod .. " + " .. shift .. " + F", function()
	local active = hl.get_active_window()
	if active ~= nil then
		hl.dispatch(hl.dsp.window.float({ window = active }))
		if active.floating then
			hl.dispatch(hl.dsp.window.resize({ x = 875, y = 600, window = active }))
			hl.dispatch(hl.dsp.window.center({ window = active }))
		end
	end
end, { description = "Toggle floating and resize window" })

hl.bind(mod .. " + P", require("config.popout").toggle, { description = "Toggle picture-in-picture / popup mode" })

--------------------------------------------------
-- 🚀 Menus
--------------------------------------------------

hl.bind(mod .. " + Space", hl.dsp.exec_cmd("qs ipc call launcher toggle"), { description = "Menu: Apps" })
hl.bind(mod .. " + W", hl.dsp.exec_cmd("qs ipc call wallpaper toggle"), { description = "Menu: Wallpapers" })
hl.bind(mod .. " + V", hl.dsp.exec_cmd("qs ipc call clipboard toggle"), { description = "Menu: Clipboard" })
hl.bind(mod .. " + M", hl.dsp.exec_cmd("qs ipc call mixer toggle"), { description = "Menu: Mixer" })
hl.bind(mod .. " + U", hl.dsp.exec_cmd("qs ipc call updates toggle"), { description = "Menu: Updates" })
hl.bind(mod .. " + N", hl.dsp.exec_cmd("qs ipc call notifs toggle"), { description = "Menu: Notifications" })
hl.bind(mod .. " + D", hl.dsp.exec_cmd("qs ipc call dotfiles toggle"), { description = "Menu: Dotfiles" })
hl.bind(mod .. " + Escape", hl.dsp.exec_cmd("qs ipc call power toggle"), { description = "Menu: PowerMenu" })
-- SUPER + / : on the French layout / is SHIFT + :, so SHIFT is part of the bind
hl.bind(mod .. " + " .. shift .. " + slash", hl.dsp.exec_cmd("qs ipc call keybinds toggle"), { description = "Menu: Keybinds" })

hl.bind(mod .. " + " .. alt .. " + Space", hl.dsp.exec_cmd("qs ipc call hub toggle"), { description = "Menu: General" })

--------------------------------------------------
-- 🔌 Session
--------------------------------------------------

hl.bind(mod .. " + Backspace", hl.dsp.exec_cmd("qs ipc call lock lock"), { description = "Lock screen" })

hl.bind(
	mod .. " + " .. shift .. " + Backspace",
	hl.dsp.exec_cmd("uwsm stop"),
	{ description = "Stop session / Logout" }
)

--------------------------------------------------
-- 🖥️ Applications
--------------------------------------------------

hl.bind(mod .. " + Return", hl.dsp.exec_cmd("uwsm-app -- xdg-terminal-exec"), { description = "Open terminal" })

hl.bind(
	mod .. " + " .. shift .. " + Return",
	hl.dsp.exec_cmd("uwsm-app -- xdg-terminal-exec --app-id=FloatingTerm"),
	{ description = "Open floating terminal" }
)

hl.bind(mod .. " + E", hl.dsp.exec_cmd("uwsm-app -- nautilus"), { description = "Open file manager (Nautilus)" })

hl.bind(mod .. " + B", hl.dsp.exec_cmd("uwsm-app -- zen-browser"), { description = "Open browser (Zen)" })

hl.bind(mod .. " + C", hl.dsp.exec_cmd("uwsm-app -- vesktop"), { description = "Open chat (Vesktop)" })

--------------------------------------------------
-- 📸 Screenshots / utilities
--------------------------------------------------

hl.bind(
	mod .. " + S",
	hl.dsp.exec_cmd("qs ipc call screenshot toggle"),
	{ description = "Menu: Screenshot" }
)

hl.bind(
	mod .. " + " .. shift .. " + R",
	hl.dsp.exec_cmd("pkill -x qs; uwsm-app -s s -- qs"),
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
-- 🖥️ Move workspace between monitors
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

hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window with mouse" })

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
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd(qs .. "audio mute"),
	{ locked = true, description = "Toggle audio mute" }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd(qs .. "audio micMute"),
	{ locked = true, description = "Toggle microphone mute" }
)

--------------------------------------------------
-- 🎵 Media keys
--------------------------------------------------

hl.bind(
	"XF86AudioNext",
	hl.dsp.exec_cmd(qs .. "media next"),
	{ locked = true, description = "Next media track" }
)
hl.bind(
	"XF86AudioPrev",
	hl.dsp.exec_cmd(qs .. "media previous"),
	{ locked = true, description = "Previous media track" }
)
hl.bind(
	"XF86AudioPlay",
	hl.dsp.exec_cmd(qs .. "media toggle"),
	{ locked = true, description = "Play/Pause media" }
)
hl.bind(
	"XF86AudioPause",
	hl.dsp.exec_cmd(qs .. "media toggle"),
	{ locked = true, description = "Play/Pause media" }
)

--------------------------------------------------
-- 🔠 Caps Lock OSD
--------------------------------------------------

hl.bind("Caps_Lock", hl.dsp.exec_cmd(qs .. "osd caps"), { release = true, description = "Caps Lock OSD toggle" })

--------------------------------------------------
-- 🎬 OBS Studio (global shortcuts)
--------------------------------------------------

hl.bind(
	"SUPER + ALT + C",
	hl.dsp.send_shortcut({ mods = "SUPER + ALT", key = "C", window = "class:^(obs)$" }),
	{ description = "OBS: Cam Scene" }
)
hl.bind(
	"SUPER + ALT + G",
	hl.dsp.send_shortcut({ mods = "SUPER + ALT", key = "G", window = "class:^(obs)$" }),
	{ description = "OBS: Game Scene" }
)
hl.bind(
	"SUPER + ALT + B",
	hl.dsp.send_shortcut({ mods = "SUPER + ALT", key = "B", window = "class:^(obs)$" }),
	{ description = "OBS: Browser Scene" }
)
hl.bind(
	"SUPER + ALT + P",
	hl.dsp.send_shortcut({ mods = "SUPER + ALT", key = "P", window = "class:^(obs)$" }),
	{ description = "OBS: Screen Scene" }
)
hl.bind(
	"SUPER + ALT + T",
	hl.dsp.send_shortcut({ mods = "SUPER + ALT", key = "T", window = "class:^(obs)$" }),
	{ description = "OBS: Term Scene" }
)

hl.bind(
	"SUPER + ALT + E",
	hl.dsp.send_shortcut({ mods = "SUPER + ALT", key = "E", window = "class:^(obs)$" }),
	{ description = "OBS: Edit Scene" }
)

hl.bind(
	"SUPER + ALT + R",
	hl.dsp.send_shortcut({ mods = "SUPER + ALT", key = "R", window = "class:^(obs)$" }),
	{ description = "OBS: Toggle Recording" }
)
hl.bind(
	"SUPER + ALT + S",
	hl.dsp.send_shortcut({ mods = "SUPER + ALT", key = "S", window = "class:^(obs)$" }),
	{ description = "OBS: Toggle Streaming" }
)
hl.bind(
	"SUPER + ALT + M",
	hl.dsp.send_shortcut({ mods = "SUPER + ALT", key = "M", window = "class:^(obs)$" }),
	{ description = "OBS: Mute Microphone" }
)
hl.bind(
	"SUPER + ALT + H",
	hl.dsp.send_shortcut({ mods = "SUPER + ALT", key = "H", window = "class:^(obs)$" }),
	{ description = "OBS: Hide Cam + Mute" }
)
