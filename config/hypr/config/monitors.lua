-- The screens, matched by their name (make, model, serial: `hyprctl monitors all`), not by the port they're
-- on: a cable moved to another port keeps its settings. The greeter uses this file too (greeter.lua).

-- any screen not named below (another machine's, a new one): its preferred mode, placed and scaled by
-- Hyprland, as in Hyprland's own default config
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

hl.monitor({ output = "desc:ASUSTek COMPUTER INC VG259QR M5LMQS094202", mode = "1920x1080@165", position = "0x0", scale = 1 })
hl.monitor({ output = "desc:iiyama Corporation PL2488H 0", mode = "1920x1080@60", position = "1920x0", scale = 1 })
-- the TV stays off: without this, Hyprland would turn it on like any other screen plugged in
hl.monitor({ output = "desc:Technical Concepts Ltd Beyond TV 0x00010000", disabled = true })
