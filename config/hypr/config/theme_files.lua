-- The theme for the apps that can only read their own format, written from theme.json (config/theme.lua)
-- every time Hyprland starts or reloads (theme/apply.sh reloads it when theme.json changes). These files
-- aren't in the dotfiles: edit theme.json, or this file.
--
--   ~/.config/hypr/hyprtoolkit.conf     hyprtoolkit apps (hyprland-dialog, the share picker...)
--   ~/.config/qt6ct/qt6ct.conf          Qt apps: style, fonts, icons
--   ~/.config/qt6ct/colors.conf         Qt apps: colours

local theme = require("config.theme")

local home = os.getenv("HOME")
local c = theme.colors
local font = theme.font

-- the note at the top of each file, with that format's comment mark
local function header(mark)
	return mark .. " Written by Hyprland from ~/.config/theme/theme.json (hypr/config/theme_files.lua):\n"
		.. mark .. " edit those, since this file is replaced on every Hyprland start and reload.\n\n"
end

-- replaces `path` in one step, so an app never reads half a file. A link there (into the dotfiles, from
-- before) is replaced too, not followed
local function write(path, text)
	local dir = path:match("^(.*)/")
	local tmp = path .. ".tmp"
	local f = io.open(tmp, "w")
	if not f then
		os.execute("mkdir -p '" .. dir .. "'")
		f = assert(io.open(tmp, "w"))
	end
	f:write(text)
	f:close()
	assert(os.rename(tmp, path))
end

-- ---------- hyprtoolkit ----------

-- 0xAARRGGBB
local function argb(name)
	return "0xFF" .. c[name]:sub(2)
end

local function hyprtoolkit()
	local size = font.appPointSize
	return header("#")
		.. table.concat({
			-- mapped the way quickshell's Theme.qml uses them
			"background = " .. argb("base"), --          Theme.bg (bar, dropdowns)
			"base = " .. argb("overlay"), --              Theme.surface (rows, buttons, inputs)
			"alternate_base = " .. argb("highlightMed"), -- hovered / unfocused input border
			"text = " .. argb("text"),
			"bright_text = " .. argb("rose"),
			"link_text = " .. argb("foam"),
			"accent = " .. argb("iris"), --               Theme.accent / Theme.border
			"accent_secondary = " .. argb("foam"),
			"",
			"font_family = " .. font.ui,
			"font_family_monospace = " .. font.mono,
			"font_size = " .. size,
			"small_font_size = " .. (size - 1),
			"h3_size = " .. (size + 1),
			"h2_size = " .. (size + 2),
			"h1_size = " .. (size + 4),
			"",
			"icon_theme = " .. theme.icons,
			"rounding_small = " .. theme.radius.medium,
			"rounding_large = " .. theme.radius.large,
		}, "\n")
		.. "\n"
end

-- ---------- qt6ct ----------

local function qt6ct()
	-- a Qt font: family, point size, then Qt's defaults for the rest
	local function qfont(family)
		return '"' .. family .. "," .. font.appPointSize .. ',-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular"'
	end
	return header(";")
		.. table.concat({
			"[Appearance]",
			"color_scheme_path=" .. home .. "/.config/qt6ct/colors.conf",
			"custom_palette=true",
			"icon_theme=" .. theme.icons,
			"standard_dialogs=default",
			"style=Fusion",
			"",
			"[Fonts]",
			"fixed=" .. qfont(font.mono),
			"general=" .. qfont(font.ui),
			"",
			"[Interface]",
			"activate_item_on_single_click=1",
			"buttonbox_layout=0",
			"cursor_flash_time=1000",
			"dialog_buttons_have_icons=1",
			"double_click_interval=400",
			"gui_effects=@Invalid()",
			"keyboard_scheme=2",
			"menus_have_icons=true",
			"show_shortcuts_in_context_menus=true",
			"stylesheets=@Invalid()",
			"toolbutton_style=4",
			"underline_shortcut=1",
			"wheel_scroll_lines=3",
			"",
			"[Troubleshooting]",
			"force_raster_widgets=1",
			"ignored_applications=@Invalid()",
		}, "\n")
		.. "\n"
end

-- Qt's palette roles, in the order qt6ct lists them: a palette colour's name, or a fixed #AARRGGBB
local roles = {
	"WindowText", "Button", "Light", "Midlight", "Dark", "Mid", "Text", "BrightText", "ButtonText", "Base",
	"Window", "Shadow", "Highlight", "HighlightedText", "Link", "LinkVisited", "AlternateBase", "NoRole",
	"ToolTipBase", "ToolTipText", "PlaceholderText",
}
local fixed = { AlternateBase = "#ff1a1c1e", NoRole = "#ff000000", PlaceholderText = "#809e9e9e" }
local groups = {
	active = {
		WindowText = "text", Button = "overlay", Light = "highlightHigh", Midlight = "highlightMed",
		Dark = "highlightLow", Mid = "overlay", Text = "muted", BrightText = "love", ButtonText = "rose",
		Base = "overlay", Window = "base", Shadow = "overlay", Highlight = "highlightHigh",
		HighlightedText = "gold", Link = "foam", LinkVisited = "iris", ToolTipBase = "highlightLow",
		ToolTipText = "subtle",
	},
	disabled = {
		WindowText = "rose", Button = "surface", Light = "highlightHigh", Midlight = "highlightMed",
		Dark = "highlightLow", Mid = "overlay", Text = "muted", BrightText = "love", ButtonText = "rose",
		Base = "overlay", Window = "base", Shadow = "overlay", Highlight = "highlightMed",
		HighlightedText = "highlightHigh", Link = "subtle", LinkVisited = "highlightHigh",
		ToolTipBase = "highlightLow", ToolTipText = "foam",
	},
	inactive = {
		WindowText = "text", Button = "overlay", Light = "highlightHigh", Midlight = "highlightMed",
		Dark = "highlightLow", Mid = "overlay", Text = "muted", BrightText = "love", ButtonText = "rose",
		Base = "overlay", Window = "base", Shadow = "overlay", Highlight = "highlightMed",
		HighlightedText = "rose", Link = "pine", LinkVisited = "muted", ToolTipBase = "highlightLow",
		ToolTipText = "iris",
	},
}

local function qt_colors()
	local lines = { header(";") .. "[ColorScheme]" }
	for _, group in ipairs({ "active", "disabled", "inactive" }) do
		local values = {}
		for i, role in ipairs(roles) do
			values[i] = fixed[role] or ("#ff" .. c[groups[group][role]]:sub(2))
		end
		lines[#lines + 1] = group .. "_colors=" .. table.concat(values, ", ")
	end
	return table.concat(lines, "\n") .. "\n"
end

-- ---------- write them ----------

for path, make in pairs({
	[home .. "/.config/hypr/hyprtoolkit.conf"] = hyprtoolkit,
	[home .. "/.config/qt6ct/qt6ct.conf"] = qt6ct,
	[home .. "/.config/qt6ct/colors.conf"] = qt_colors,
}) do
	-- a failure here mustn't stop the rest of the Hyprland config
	local ok, err = pcall(function()
		write(path, make())
	end)
	if not ok then print("theme_files: " .. path .. ": " .. tostring(err)) end
end
