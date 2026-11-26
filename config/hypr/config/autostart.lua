-- Each in uwsm's slice for what it is: -s s (session) for the shell, which the session needs (bar, lock
-- screen); -s b (background) for daemons. Apps opened later go to the default app slice.
-- hypridle and the polkit agent are user services (install/steps/services.sh).
hl.on("hyprland.start", function()
	hl.exec_cmd("uwsm-app -s s -- qs")
	hl.exec_cmd("uwsm-app -s b -- wl-paste --watch clipvault store")
	hl.exec_cmd("uwsm-app -s b -- bt-agent")
	hl.exec_cmd("uwsm-app -s b -- easyeffects --service-mode -w")
	--hl.exec_cmd("sleep 5 && bluetoothctl power on && bluetoothctl connect A8:E6:E8:04:97:29")

	hl.exec_cmd("hyprpm reload")
end)
