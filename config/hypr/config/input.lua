-- Input configuration
hl.config({
	input = {
		kb_layout = "fr",

		follow_mouse = 1,

		sensitivity = 0, -- -1.0 to 1.0
		accel_profile = "flat",

		touchpad = {
			natural_scroll = true,
		},
	},
})

--------------------------------------------------
-- 🤏 Gesture
--------------------------------------------------

hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})

--------------------------------------------------
-- 🖱️ Trackpad device config
--------------------------------------------------

hl.device({
	name = "bcm5974",
	-- accel_profile intentionally empty in your config
})
