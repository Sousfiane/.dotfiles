# kitty's colours, font and opacity, from the merged theme (~/.local/state/theme/current.json: theme.json in
# config/theme, the fonts picked and the current palette), which quickshell, Hyprland, Neovim and tmux read
# too. kitty.conf runs this with `geninclude` on every config load (ctrl+shift+f5 reloads) and reads what it
# prints as config: nothing is written to disk.

import json
import os
import subprocess

theme_dir = os.path.expanduser("~/.config/theme")


def read(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


# the merged theme (~/.local/state/theme/current.json, from theme.json, the fonts picked and the current
# palette): written first by merge.sh if it isn't there yet
current = os.path.expanduser("~/.local/state/theme/current.json")
if not os.path.isfile(current):
    subprocess.run([f"{theme_dir}/merge.sh"], check=False)
theme = read(current)

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
