#!/usr/bin/env bash
# The dotfiles' only entry point. Run it as your user (sudo is asked once, when needed).
#
#   install/install.sh                    every step, in order
#   install/install.sh packages links     only these steps (after a `git pull`, say)
#   install/install.sh check              how the installed packages differ from the lists
#   install/install.sh calendar           an optional step: runs only when named
#
# Every step checks before it acts, so running it again is safe: it only does what's missing.

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# the order steps run in; each is install/steps/<name>.sh
STEPS=(pacman yay packages links services system)
# steps a full install leaves out, run by name whenever: calendar needs the desktop session (the keyring)
OPTIONAL=(calendar)

LOG="$HOME/.cache/dotfiles-install.log"

usage() {
    echo "usage: install/install.sh [step...] | check"
    echo "steps: ${STEPS[*]}"
    echo "optional, by name only: ${OPTIONAL[*]}"
}

# ---------- check: the lists against the machine ----------

check() {
    local explicit listed known
    explicit=$(pacman -Qqe | sort)
    listed=$(wanted_packages | sort -u)
    # installed by archinstall or by the steps themselves: not missing from the lists
    known=$( (echo "$listed"; read_list system.txt) | sort -u)

    title "Installed, but in no list (add to apps.txt, or uninstall)"
    comm -23 <(echo "$explicit") <(echo "$known") | columns

    title "In the lists, but not installed (install.sh packages)"
    while read -r p; do
        if ! is_installed "$p"; then echo "$p"; fi
    done <<<"$listed" | columns

    title "Still installed, but in remove.txt (install.sh packages)"
    read_list remove.txt | while read -r p; do
        if is_installed "$p"; then echo "$p"; fi
    done | columns
}

# stdin in columns, or "(none)"
columns() {
    local items
    items=$(cat)
    if [[ -z $items ]]; then
        echo "  (none)"
    else
        echo "$items" | column -c "${COLUMNS:-100}"
    fi
}

# ---------- main ----------

if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
    usage
    exit 0
fi

if [[ ${1:-} == "check" ]]; then
    check
    exit 0
fi

[[ $EUID -eq 0 ]] && fail "Run this as your user, not as root: sudo is asked for when needed."
[[ $DOTFILES == "$HOME/.dotfiles" ]] || fail "The repo must be at ~/.dotfiles (it's at $DOTFILES): configs and scripts refer to it there."

# what to run: the steps asked for, or all of them. Checked before anything runs.
selected=("$@")
[[ ${#selected[@]} -eq 0 ]] && selected=("${STEPS[@]}")
for s in "${selected[@]}"; do
    [[ " ${STEPS[*]} ${OPTIONAL[*]} " == *" $s "* ]] || { usage; fail "Unknown step: $s"; }
    [[ -f "$INSTALL_DIR/steps/$s.sh" ]] || fail "Missing step script: install/steps/$s.sh"
done

# everything on screen also goes to the log
mkdir -p "$(dirname "$LOG")"
exec > >(tee -a "$LOG") 2>&1
info "Log: $LOG"

# sudo once, kept alive until the install ends; not asked when only optional steps run (they don't need it)
needs_sudo=false
for s in "${selected[@]}"; do
    [[ " ${STEPS[*]} " == *" $s "* ]] && needs_sudo=true
done
if $needs_sudo; then
    sudo -v
    while true; do
        sudo -n true
        sleep 50
        kill -0 "$$" 2>/dev/null || exit
    done 2>/dev/null &
    SUDO_KEEPALIVE=$!
    trap 'kill $SUDO_KEEPALIVE 2>/dev/null' EXIT
fi

for s in "${selected[@]}"; do
    title "$s"
    bash "$INSTALL_DIR/steps/$s.sh"
done

title "Done"
success "Ran: ${selected[*]}"
