-- Mod keys
local mod = "SUPER"
local shift = "SHIFT"
local ctrl = "CTRL"
local alt = "ALT"

-- OSD client
local osdclient = "swayosd-client --monitor \"$(hyprctl monitors -j | jq -r '.[] | select(.focused == true).name')\""

--------------------------------------------------
-- 🪟 Window management
--------------------------------------------------

hl.bind(mod .. " + Q", hl.dsp.window.close())

hl.bind(mod .. " + F", hl.dsp.window.fullscreen())

hl.bind(
	mod .. " + " .. shift .. " + F",
	hl.dsp.exec_cmd(
		"hyprctl --batch 'dispatch togglefloating; dispatch resizeactive exact 875 600; dispatch centerwindow'"
	)
)

hl.bind(mod .. " + P", hl.dsp.exec_cmd("popup"))

--------------------------------------------------
-- 🚀 Menus
--------------------------------------------------

hl.bind(mod .. " + Space", hl.dsp.exec_cmd("os-menu apps"))
hl.bind(mod .. " + Escape", hl.dsp.exec_cmd("os-menu system"))
hl.bind(mod .. " + W", hl.dsp.exec_cmd("os-menu wallpapers"))
hl.bind(mod .. " + V", hl.dsp.exec_cmd("os-menu clipboard"))
hl.bind(mod .. " + D", hl.dsp.exec_cmd("os-menu dotfiles"))

hl.bind(mod .. " + " .. shift .. " + Escape", hl.dsp.exec_cmd("os-menu settings"))

hl.bind(mod .. " + " .. alt .. " + Space", hl.dsp.exec_cmd("os-menu"))

--------------------------------------------------
-- 🔌 Session
--------------------------------------------------

hl.bind(mod .. " + Backspace", hl.dsp.exec_cmd("uwsm-app -- hyprlock"))

hl.bind(mod .. " + " .. shift .. " + Backspace", hl.dsp.exec_cmd("uwsm stop"))

--------------------------------------------------
-- 🖥️ Applications
--------------------------------------------------

hl.bind(mod .. " + Return", hl.dsp.exec_cmd("uwsm-app -- xdg-terminal-exec"))

hl.bind(mod .. " + " .. shift .. " + Return", hl.dsp.exec_cmd("uwsm-app -- xdg-terminal-exec --app-id=FloatingTerm"))

hl.bind(mod .. " + N", hl.dsp.exec_cmd("uwsm-app -- nautilus"))

hl.bind(mod .. " + B", hl.dsp.exec_cmd("uwsm-app -- zen-browser"))

hl.bind(mod .. " + C", hl.dsp.exec_cmd("uwsm-app -- discord"))

--------------------------------------------------
-- 📸 Screenshots / utilities
--------------------------------------------------

hl.bind(mod .. " + S", hl.dsp.exec_cmd("uwsm-app -- hyprshot -m region --clipboard-only"))

hl.bind(mod .. " + " .. shift .. " + S", hl.dsp.exec_cmd("uwsm-app -- hyprshot -m window --clipboard-only"))

hl.bind(mod .. " + " .. shift .. " + R", hl.dsp.exec_cmd("pkill waybar && uwsm-app -- waybar"))

--------------------------------------------------
-- 🧭 Focus (vim-style)
--------------------------------------------------

hl.bind(mod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(mod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + L", hl.dsp.focus({ direction = "right" }))

--------------------------------------------------
-- 🔄 Swap windows
--------------------------------------------------

hl.bind(mod .. " + " .. shift .. " + H", hl.dsp.layout("swapcol l"))
hl.bind(mod .. " + " .. shift .. " + L", hl.dsp.layout("swapcol r"))

--------------------------------------------------
-- 🖥️ Move workspace between monitors
--------------------------------------------------

hl.bind(mod .. " + " .. ctrl .. " + H", hl.dsp.workspace.move({ monitor = "l" }))

hl.bind(mod .. " + " .. ctrl .. " + L", hl.dsp.workspace.move({ monitor = "r" }))

--------------------------------------------------
-- 📑 Workspaces (1–9)
--------------------------------------------------

-- Keycodes for AZERTY (1–9)
local codes = { 10, 11, 12, 13, 14, 15, 16, 17, 18 }

for i, code in ipairs(codes) do
	-- Switch workspace
	hl.bind(mod .. " + code:" .. code, hl.dsp.focus({ workspace = i }))

	-- Move window to workspace
	hl.bind(mod .. " + " .. shift .. " + code:" .. code, hl.dsp.window.move({ workspace = i }))
end

--------------------------------------------------
-- 🔁 Workspace cycling
--------------------------------------------------

hl.bind(mod .. " + TAB", hl.dsp.focus({ workspace = "m+1" }))

hl.bind(mod .. " + " .. shift .. " + TAB", hl.dsp.focus({ workspace = "m-1" }))

hl.bind(mod .. " + " .. ctrl .. " + TAB", hl.dsp.focus({ workspace = "previous" }))

--------------------------------------------------
-- 📏 Resize windows
--------------------------------------------------

hl.bind(mod .. " + " .. alt .. " + H", hl.dsp.exec_cmd("hyprctl dispatch resizeactive -100 0"))

hl.bind(mod .. " + " .. alt .. " + J", hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 100"))

hl.bind(mod .. " + " .. alt .. " + K", hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 -100"))

hl.bind(mod .. " + " .. alt .. " + L", hl.dsp.exec_cmd("hyprctl dispatch resizeactive 100 0"))

--------------------------------------------------
-- 🖱️ Mouse actions
--------------------------------------------------

hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })

hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

--------------------------------------------------
-- 🔊 Volume / brightness (OSD)
--------------------------------------------------

hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd(osdclient .. " --output-volume +5"),
	{ locked = true, repeating = true }
)

hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd(osdclient .. " --output-volume -5"),
	{ locked = true, repeating = true }
)

hl.bind("XF86AudioMute", hl.dsp.exec_cmd(osdclient .. " --output-volume mute-toggle"), { locked = true })

hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(osdclient .. " --input-volume mute-toggle"), { locked = true })

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(osdclient .. " --brightness +5"), { locked = true })

hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(osdclient .. " --brightness -5"), { locked = true })

hl.bind("XF86KbdBrightnessUp", hl.dsp.exec_cmd("kb-backlight +26"), { locked = true })

hl.bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd("kb-backlight 26-"), { locked = true })

--------------------------------------------------
-- 🎵 Media keys
--------------------------------------------------

hl.bind("XF86AudioNext", hl.dsp.exec_cmd(osdclient .. " --playerctl next"), { locked = true })

hl.bind("XF86AudioPrev", hl.dsp.exec_cmd(osdclient .. " --playerctl previous"), { locked = true })

hl.bind("XF86AudioPlay", hl.dsp.exec_cmd(osdclient .. " --playerctl play-pause"), { locked = true })

hl.bind("XF86AudioPause", hl.dsp.exec_cmd(osdclient .. " --playerctl play-pause"), { locked = true })

--------------------------------------------------
-- 🔠 Caps Lock OSD
--------------------------------------------------

hl.bind("Caps_Lock", hl.dsp.exec_cmd(osdclient .. " --caps-lock"))
