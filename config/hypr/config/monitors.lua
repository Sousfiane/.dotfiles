hl.monitor({ output = "DP-1", mode = "1920x1080@165", position = "0x0", scale = 1 })
hl.monitor({ output = "DP-2", mode = "1920x1080@60", position = "1920x0", scale = 1 })
-- the TV on HDMI stays off: without this, Hyprland turns on any screen plugged in
hl.monitor({ output = "HDMI-A-1", disabled = true })
