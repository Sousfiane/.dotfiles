# .dotfiles

Arch Linux with Hyprland and a Quickshell desktop.

## Installing

On a fresh Arch, set up with **archinstall**:

- **Profile:** Desktop → Hyprland, with **sddm** as the greeter (the install also lists them itself, so the "minimal" profile works too)
- **Audio:** PipeWire • **Bluetooth:** on • **Network:** "Use NetworkManager" • **Graphics:** the proprietary NVIDIA driver (`nvidia-open`)

Then, as your user:

```sh
bash <(curl -fsSL https://raw.githubusercontent.com/Sousfiane/.dotfiles/main/install/bootstrap.sh)
```

It clones this repo to `~/.dotfiles` and runs `install/install.sh`, which goes through `install/steps/` in order:

| Step | Does |
|---|---|
| `pacman` | enables multilib, full system upgrade |
| `yay` | builds the AUR helper |
| `packages` | installs `packages/desktop.txt` and `packages/apps.txt`, removes `packages/remove.txt` (what archinstall adds that the desktop replaces) |
| `links` | links the files where their folder says (see below) |
| `services` | enables NetworkManager, Bluetooth and sddm |
| `system` | zsh as the login shell, the GTK theme |

**The repo must live at `~/.dotfiles`:** configs and scripts refer to it there (`$DOTFILES`, set in `home/zprofile`), and `install.sh` refuses to run from anywhere else.

Every step checks before it acts, so running it again is safe. Afterwards:

```sh
~/.dotfiles/install/install.sh packages links   # only some steps (after a git pull)
~/.dotfiles/install/install.sh check            # installed packages vs. the lists
```

Once in the desktop, from a terminal (the keyring isn't reachable from a console login):

```sh
~/.dotfiles/install/install.sh calendar         # the Nextcloud calendar: server, user, app password
```

It checks them against the server, then stores them in the keyring, never in the repo. Run it again to replace them.

After opening and closing Spotify once:

```sh
~/.dotfiles/install/install.sh spicetify        # the Spotify theme
```

Only the choices are in the repo (`install/steps/spicetify.sh`, plus `Themes` and `Extensions`); spicetify keeps its own `config-xpui.ini` in `~/.config/spicetify`, since it writes version numbers into it. The step also makes Spotify's menu entry open it through `spotify-themed`, which applies the theme again by itself when Spotify was updated or the palette changed, so the step is only needed once.

## Layout

Where a file sits in the repo is where it goes:

| In the repo | Linked to |
|---|---|
| `config/<app>/<entry>` | `~/.config/<app>/<entry>` |
| `home/<name>` | `~/.<name>` (`home/zshrc` → `~/.zshrc`) |
| `local/<folder>/<entry>` | `~/.local/<folder>/<entry>` (`local/bin/popup` → `~/.local/bin/popup`) |

Each entry at the top of an app folder is one link, so a file added inside a subfolder is live at once. A new app folder, or a new file at its top, needs `install.sh links`. Names starting with a dot (editor files) aren't linked.

## Theme

`config/theme/theme.json` (linked to `~/.config/theme/theme.json`) holds the fonts, corner radii, opacities, icons, the terminal's colour mapping, and the default palette. The colours are in that palette, `config/theme/palettes/<name>.json` (Rosé Pine, Moon and Dawn), which also says whether it's dark, and which GTK theme (and GTK colour scheme: `prefer-light` for all three, or libadwaita adds its own dark style on top) and spicetify scheme go with it. Each app reads both itself, with nothing generated:

| App | Reads it | A change shows |
|---|---|---|
| Quickshell | `config/Theme.qml` | at once |
| Hyprland | `config/theme.lua` (with `config/json.lua`) | on `hyprctl reload` |
| kitty | `theme.py`, through `geninclude` | on ctrl+shift+F5, or in new windows |
| Neovim | `lua/plugins/colors.lua`, as the rose-pine plugin's palette | at once (it watches the files) |
| tmux | `theme.sh` (with `jq`), which also lays out the status bar | on `tmux source-file ~/.config/tmux/tmux.conf` |
| fzf, ls | `config/zsh/theme.zsh`: `FZF_DEFAULT_OPTS`, and `LS_COLORS` from vivid's theme named by the palette (set in `zprofile`, checked again by `zshrc`) | at the next prompt |
| zsh prompt | `config/zsh/p10k.zsh` uses only the terminal's 16 colours, so it follows kitty | with kitty |

The apps keep only what each colour is used for.

`theme` lists the palettes and `theme moon` (or `theme next`) switches. The current palette is kept in `~/.local/state/theme/palette`, out of the repo, so switching never shows up in git; `theme.json`'s `"palette"` is only what a new machine starts with. The hub's Theme picker (`E` in the hub, or `qs ipc call theme toggle`) does the same, with a strip of each palette's colours.

Switching, or saving `theme.json` or a palette, updates everything: Quickshell follows the file and then runs `config/theme/apply.sh`, which reloads Hyprland, kitty and tmux and sets the GTK theme, its colour scheme, app font and icon theme. Spotify can't switch while it's open: a notification offers to restart it with the new theme, and otherwise it gets it the next time it opens. A save that doesn't parse changes nothing. Neovim watches the files itself.

hyprtoolkit and qt6ct can only read their own format, so Hyprland writes `~/.config/hypr/hyprtoolkit.conf`, `~/.config/qt6ct/qt6ct.conf` and `~/.config/qt6ct/colors.conf` from `theme.json` every time it starts or reloads (`config/hypr/config/theme_files.lua`). They aren't in the repo: change `theme.json` or that file, not them (the qt6ct window's changes don't last).
