# kitty's colours, font and opacity, from ~/.config/theme/theme.json (config/theme/theme.json in the
# dotfiles), which quickshell and Hyprland read too. kitty.conf runs this with `geninclude` on every config
# load (ctrl+shift+f5 reloads) and reads what it prints as config: nothing is written to disk.

import json
import os

with open(os.path.expanduser("~/.config/theme/theme.json"), encoding="utf-8") as f:
    theme = json.load(f)

c = theme["colors"]
term = theme["terminal"]

settings = {
    "font_family": theme["font"]["mono"],
    "font_size": theme["font"]["monoPointSize"],
    "background_opacity": theme["opacity"]["terminal"],
    "foreground": c["text"],
    "background": c["base"],
    "selection_foreground": c["text"],
    "selection_background": c["highlightMed"],
    "cursor": c["iris"],
    "cursor_text_color": c["text"],
    "url_color": c["iris"],
    "active_tab_foreground": c["text"],
    "active_tab_background": c["overlay"],
    "inactive_tab_foreground": c["muted"],
    "inactive_tab_background": c["base"],
}

# color0..15, in the terminal's order; theme.json names a palette colour for each
order = ["black", "red", "green", "yellow", "blue", "magenta", "cyan", "white"]
for i, name in enumerate(order):
    settings[f"color{i}"] = c[term[name]]
    settings[f"color{i + 8}"] = c[term["bright" + name.capitalize()]]

for key, value in settings.items():
    print(key, value)
