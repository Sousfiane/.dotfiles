# kitty's colours, font and opacity, from ~/.config/theme/theme.json and the current palette (config/theme
# in the dotfiles), which quickshell, Hyprland, Neovim and tmux read too. kitty.conf runs this with
# `geninclude` on every config load (ctrl+shift+f5 reloads) and reads what it prints as config: nothing is
# written to disk.

import json
import os

theme_dir = os.path.expanduser("~/.config/theme")


def read(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


# the current palette: ~/.local/state/theme/palette (out of the repo, written by `theme`), or the settings'
# default
def current_palette(default):
    try:
        with open(os.path.expanduser("~/.local/state/theme/palette"), encoding="utf-8") as f:
            return f.readline().strip() or default
    except OSError:
        return default


# the settings, with the current palette on top, and the fonts picked in the theme picker over theirs
# (~/.local/state/theme/fonts.json, written by `theme font`)
theme = read(f"{theme_dir}/theme.json")
try:
    theme["font"].update(read(os.path.expanduser("~/.local/state/theme/fonts.json")))
except (OSError, ValueError, AttributeError, TypeError):
    pass
theme.update(read(f"{theme_dir}/palettes/{current_palette(theme['palette'])}.json"))

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
