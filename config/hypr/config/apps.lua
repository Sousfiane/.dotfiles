-- Focus or open, as clicking an app in macOS's Dock: SUPER + B, C, E (bindings.lua) go to the app's most
-- recently used window wherever it is (its workspace shown, the strip scrolled to it), or open the app where
-- you are when it isn't running. Pressed again while the app is in front, they go through its other
-- windows. The terminal (SUPER + Return) isn't one of them: it always opens a new one, here.
local M = {}

-- a bind's action for the app whose windows have class `class`, started with `command`
function M.focus_or_open(class, command)
	return function()
		local windows = {}
		for _, w in ipairs(hl.get_windows()) do
			if w.class == class and w.mapped and not w.hidden then
				windows[#windows + 1] = w
			end
		end
		if #windows == 0 then
			hl.dispatch(hl.dsp.exec_cmd(command))
			return
		end
		table.sort(windows, function(a, b)
			return a.focus_history_id < b.focus_history_id
		end)
		-- in front already: the one used longest ago, so pressing again goes round them all
		local target = windows[1]
		if target.focus_history_id == 0 and #windows > 1 then
			target = windows[#windows]
		end
		hl.dispatch(hl.dsp.focus({ window = target }))
	end
end

return M
