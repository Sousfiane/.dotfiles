#!/bin/sh
# The session the greeter (greeter.qml) starts once someone logs in, run by greetd as that user.
#
# A script rather than a command line in greeter.qml: greetd joins the command's words with spaces and runs
# the result with `sh -c`, quoting nothing, so a `sh -c '...'` command there falls apart (only `printf` ran,
# and the session ended at once: a login loop). Its path, the one word greeter.qml sends, has nothing to split.
#
# Started through the user's login shell, as a display manager does: its profile (~/.zprofile: ~/.local/bin in
# PATH, DOTFILES, the theme's colours) runs first, and uwsm hands that environment to the whole session.
# Output would print on the console while Hyprland comes up (a few seconds): the console is cleared, its
# cursor hidden, and the output dropped (uwsm and Hyprland log to the journal anyway).

printf '\033[2J\033[3J\033[H\033[?25l'
login=$(getent passwd "$(id -un)" | cut -d: -f7)
exec "${login:-/bin/sh}" -l -c 'exec uwsm start -e -D Hyprland hyprland.desktop' >/dev/null 2>&1
