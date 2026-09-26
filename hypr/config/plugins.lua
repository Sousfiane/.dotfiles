if hl.plugin.csgo_vulkan_fix ~= nil then
	hl.plugin.csgo_vulkan_fix.vkfix_app({ app = "cs2", w = 1280, h = 960 })
	hl.config({
		plugin = {
			csgo_vulkan_fix = {
				fix_mouse = true,
			},
		},
	})
end
