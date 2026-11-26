#!/usr/bin/env bash
# The Nextcloud calendar shown in the hub: asks for the server, user and app password, checks them against
# the server, and stores them in the keyring, where config/quickshell/scripts/calendar.py reads them
# (service=nextcloud-caldav, with url and user as attributes). Nothing goes into the dotfiles.
#
# Optional: not part of a full install (the keyring needs the desktop session). Run it from a terminal in
# the desktop, whenever: `install/install.sh calendar`. Running it again replaces the stored account.

source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

SERVICE="nextcloud-caldav"

command -v secret-tool &>/dev/null || fail "secret-tool is missing (libsecret, in packages/desktop.txt: run the packages step)"
[[ -n ${WAYLAND_DISPLAY:-} ]] || fail "Run this from a terminal in your desktop: the keyring isn't reachable from a console login."

# ---------- what's stored now ----------

current=$(secret-tool search --all "service" "$SERVICE" 2>&1 | sed -n 's/^attribute\.\(url\|user\) = //p' | paste -sd ' ' -)
if [[ -n $current ]]; then
    info "Stored now: $current"
    user "Replace it? [y/N]"
    read -r -n 1 key </dev/tty
    echo
    [[ $key == [yY] ]] || { success "Kept as it is"; exit 0; }
fi

# ---------- ask ----------

# prints the answer (non-empty); the prompt goes to stderr, since the caller captures stdout
ask() {
    local prompt=$1 secret=${2:-} value=""
    while [[ -z $value ]]; do
        user "$prompt" >&2
        if [[ -n $secret ]]; then
            read -r -s value </dev/tty
            echo >&2
        else
            read -r value </dev/tty
        fi
    done
    printf '%s' "$value"
}

url=$(ask "Nextcloud address (e.g. https://cloud.example.com)")
url=${url%/}
[[ $url == http://* || $url == https://* ]] || url="https://$url"
name=$(ask "User name")
info "Use an app password, not your account password (Nextcloud: Settings → Security → Devices & sessions)"
password=$(ask "App password (not shown)" secret)

# ---------- check it against the server ----------

# the credentials go to curl on its standard input, never on its command line (where any process could read
# them). In curl's config syntax a quoted value takes \ as an escape, so \ and " are escaped, in that order
quote() {
    local s=${1//\\/\\\\}
    printf '%s' "${s//\"/\\\"}"
}
# the user name in the address, %-encoded (a space, say)
name_uri=$(jq -rn --arg s "$name" '$s | @uri')
info "Checking with $url"
status=$(printf 'user = "%s:%s"\n' "$(quote "$name")" "$(quote "$password")" |
    curl -s -o /dev/null -w '%{http_code}' --max-time 15 -K - \
        -X PROPFIND -H "Depth: 0" "$url/remote.php/dav/calendars/$name_uri/") || status="000"

case $status in
    207) success "The server accepts them" ;;
    401) fail "Wrong user name or app password: nothing stored" ;;
    404) fail "No calendars for $name at $url (is it the Nextcloud address?): nothing stored" ;;
    000) fail "Couldn't reach $url: nothing stored" ;;
    *) fail "The server answered HTTP $status: nothing stored" ;;
esac

# ---------- store ----------

secret-tool clear "service" "$SERVICE" 2>/dev/null || true      # one account only: the old one goes
printf '%s' "$password" | secret-tool store --label="Nextcloud calendar" "service" "$SERVICE" "url" "$url" "user" "$name"
success "Stored in the keyring: the hub's calendar picks it up the next time it opens"
