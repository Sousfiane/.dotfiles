# .dotfiles

Arch Linux with Hyprland and a Quickshell desktop.

## Installing

On a fresh Arch, set up with **archinstall**:

- **Profile:** "minimal": the install brings the desktop itself, the NVIDIA driver (`nvidia-open`) included
- **Audio:** PipeWire • **Bluetooth:** on • **Network:** "Use NetworkManager"

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
| `services` | enables NetworkManager, Bluetooth and sddm, and the session's user services (Quickshell, hypridle); disables hyprpolkitagent, since Quickshell is the polkit agent |
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

At the first login, a terminal opens by itself to set up Hyprland's plugins (hyprbars, the CS2 fix): hyprpm builds them for the running Hyprland, so it can't happen during the install, and it asks for sudo. The same from a terminal, after a Hyprland upgrade say:

```sh
~/.dotfiles/install/install.sh plugins          # hyprpm: the plugins added, enabled, up to date
```

After opening and closing Spotify once:

```sh
~/.dotfiles/install/install.sh spicetify        # the Spotify theme
```

Only the choices are in the repo (`install/steps/spicetify.sh`, plus `Themes` and `Extensions`); spicetify keeps its own `config-xpui.ini` in `~/.config/spicetify`, since it writes version numbers into it. The step also makes Spotify's menu entry open it through `spotify-themed`, which applies the theme again by itself when Spotify was updated or the palette changed, so the step is only needed once.

For a login screen in the theme (greetd with a Quickshell greeter, instead of sddm):

```sh
~/.dotfiles/install/install.sh greeter          # installs it in /etc/greetd, then asks before switching
```

It shows the lock screen itself (the same `LockFace.qml`) and logs in to the same uwsm session. Its files are in the home like the rest, `config/hypr/greeter.lua` and `config/quickshell/greeter.qml` (its parts in `config/quickshell/modules/greeter`: the theme, logging in, the power buttons): greetd runs them as its `greeter` user, which the step lets cross the home with an ACL (`setfacl -m u:greeter:x ~`: it can't list the home, only reach paths it knows). So it reads the theme, the wallpaper, the monitors and the keyboard as they are, and changes to them need nothing more. If the greeter ever fails to come up (Quickshell broken by an update, say), Ctrl+Alt+F2 gives a text console, where `uwsm start hyprland.desktop` starts the desktop. To go back to sddm: `sudo systemctl disable greetd && sudo systemctl enable sddm`.

## Layout

Where a file sits in the repo is where it goes:

| In the repo | Linked to |
|---|---|
| `config/<app>/<entry>` | `~/.config/<app>/<entry>` |
| `config/<file>` | `~/.config/<file>` (`config/xdg-terminals.list`) |
| `home/<name>` | `~/.<name>` (`home/zshrc` → `~/.zshrc`) |
| `local/<folder>/<entry>` | `~/.local/<folder>/<entry>` (`local/bin/theme` → `~/.local/bin/theme`) |

Each entry at the top of an app folder is one link, so a file added inside a subfolder is live at once. A new app folder, or a new file at its top, needs `install.sh links`. Names starting with a dot (editor files) aren't linked.

## Session

The login screen (sddm, or greetd with the Quickshell greeter) starts Hyprland through **uwsm**, which runs the session as systemd units:

- the environment (Wayland backends, NVIDIA variables...) is in `config/uwsm/env`, plus `env-hyprland` for Hyprland only, so every app gets it, D-Bus-activated ones included
- Quickshell (`install/units/quickshell.service`) and hypridle are user services, started with the session and restarted if they crash; Quickshell is also the polkit agent (its password prompt)
- `hypr/config/autostart.lua` starts the background daemons (clipboard history, the Bluetooth agent, EasyEffects) with `uwsm-app`, in the background slice
- apps opened from the keybinds, the launcher and the dock go through `uwsm-app` too, and SUPER + SHIFT + Backspace (or the power menu) ends the session with `uwsm stop`

## Theme

`config/theme/theme.json` (linked to `~/.config/theme/theme.json`) holds the fonts, corner radii, opacities, icons, the terminal's colour mapping, and the default palette. The colours are in that palette, `config/theme/palettes/<name>.json` (Rosé Pine, Moon and Dawn), which also says whether it's dark, and which GTK theme (and GTK colour scheme: `prefer-light` for all three, or libadwaita adds its own dark style on top) and spicetify scheme go with it. Each app reads both itself, with nothing generated:

| App | Reads it | A change shows |
|---|---|---|
| Quickshell | `config/Theme.qml` | at once |
| Hyprland | `config/theme.lua` (with `config/json.lua`) | on `hyprctl reload` |
| kitty | `theme.py`, through `geninclude` | on ctrl+shift+F5, or in new windows |
| Neovim | `lua/plugins/colors.lua`, as the rose-pine plugin's palette | at once (it watches the files) |
| tmux | `theme.sh` (with `jq`), which also lays out the status bar | on `tmux source-file ~/.config/tmux/tmux.conf` |
| fzf, ls | `config/zsh/theme.zsh`: `FZF_DEFAULT_OPTS`, and `LS_COLORS` from vivid's theme named by the palette (set in `zprofile`, checked again by `zshrc` before each command and fzf key binding) | with the next command |
| zsh prompt | `config/zsh/prompt.zsh` uses only the terminal's 16 colours, so it follows kitty | with kitty |

The apps keep only what each colour is used for. The shell scripts among them (`theme`, `apply.sh`, `files.sh`, tmux's `theme.sh`, the Spotify ones) find the current palette through `config/theme/lib.sh`.

`theme` lists the palettes and `theme moon` (or `theme next`) switches. The current palette is kept in `~/.local/state/theme/palette`, out of the repo, so switching never shows up in git; `theme.json`'s `"palette"` is only what a new machine starts with. The hub's Theme picker (`E` in the hub, or `qs ipc call theme toggle`) does the same, with a strip of each palette's colours. Fonts work the same way: `theme font` lists the three (`ui` for Quickshell, `mono` for kitty and window titles, `app` for GTK and Qt apps), `theme font app "Noto Sans"` changes one, `theme font app size 11` sets its size (pixels for `ui`, points for the others) and `theme font app default` goes back to `theme.json`'s. The choices are kept in `~/.local/state/theme/fonts.json`, and the picker's Fonts rows open a list of the installed fonts, each drawn in itself, with − and + (or the `-` and `+` keys) for the size.

Switching, or saving `theme.json` or a palette, updates everything: Quickshell follows the file and then runs `config/theme/apply.sh`, which reloads Hyprland, kitty and tmux and sets the GTK theme, its colour scheme, app font and icon theme. Spotify can't switch while it's open, so it restarts by itself with the new theme. A save that doesn't parse changes nothing. Neovim watches the files itself.

hyprtoolkit and hyprqt6engine (the Qt apps' theme, with the Darkly style) can only read their own format, so `config/theme/files.sh` writes `~/.config/hypr/hyprtoolkit.conf`, `~/.config/hypr/hyprqt6engine.conf` and `~/.config/hypr/hyprqt6engine-colors.conf` from `theme.json` and the palette, and the colour groups in `~/.config/kdeglobals` that Darkly reads too (the menu bar, text fields); `apply.sh` runs it on every theme change. They aren't in the repo: change `theme.json` or that script, not them.
