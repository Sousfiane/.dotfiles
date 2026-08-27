local hostname = os.getenv("HOSTNAME") or ""

if hostname == "PC" then
	hl.monitor({ output = "DP-1", mode = "1920x1080@165", position = "0x0", scale = 1 })
	hl.monitor({ output = "DP-2", mode = "1920x1080@60", position = "1920x0", scale = 1 })
	hl.monitor({ output = "HDMI-A-1", mode = "3840x2160@120", position = "-3840x0,1", scale = 1, disabled = true })
else
	hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
end
