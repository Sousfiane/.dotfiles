#!/bin/sh
# SSH_ASKPASS helper for the dotfiles panel: answers ssh's passphrase prompt with what was typed in the
# panel, handed over in the environment of that one git command (see services/Dotfiles.qml).
printf '%s\n' "$QS_SSH_PASS"
