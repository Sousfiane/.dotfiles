#!/bin/sh
# The session the greeter (greeter.qml) starts once someone logs in, run by greetd as that user.
#
# A script rather than a command line in greeter.qml: greetd joins the command's words with spaces and runs
# the result with `sh -c`, quoting nothing, so a `sh -c '...'` command there falls apart (only `printf` ran,
# and the session ended at once: a login loop). Its path, the one word greeter.qml sends, has nothing to split.
#
# Started through the user's login shell, as a display manager does: its profile (~/.zprofile: ~/.local/bin in
# PATH, DOTFILES, the theme's colours) runs first, and uwsm hands that environment to the whole session.
# Output would print on the console while Hyprland comes up: it's dropped (uwsm and Hyprland log to the journal
# anyway). Nothing is written to the console either: the GPU is changing hands then, between the greeter's
# Hyprland and the session's, and the NVIDIA driver is touchy about it (a 3 s "Flip event timeout").
#
# -g -1: no check that the system reached graphical.target. When it hasn't (a boot to multi-user.target, greetd
# started by hand) uwsm waits 5 s for nothing: greetd is what logged us in, so this is the graphical session.

login=$(getent passwd "$(id -un)" | cut -d: -f7)
exec "${login:-/bin/sh}" -l -c 'exec uwsm start -g -1 -e -D Hyprland hyprland.desktop' >/dev/null 2>&1
