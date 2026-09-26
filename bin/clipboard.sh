#!/usr/bin/env bash
#
# clipvault + wofi wrapper with image thumbnails
#
# Dependencies:
#   clipvault
#   wofi
#   wl-copy
#   gawk
#   ImageMagick (magick) -- only required for image thumbnails
#
# Usage:
#   ./clipboard.sh
#

set -uo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

readonly CACHE_DIR="${XDG_CACHE_HOME:-"$HOME/.cache"}/clipvault/thumbs"
readonly THUMB_SIZE="${CLIPVAULT_THUMB_SIZE:-256}"
readonly WOFI_WIDTH="${CLIPVAULT_WOFI_WIDTH:-700}"
readonly WOFI_IMAGE_SIZE="${CLIPVAULT_WOFI_IMAGE_SIZE:-100}"

# ---------------------------------------------------------------------------
# Dependencies
# ---------------------------------------------------------------------------

for cmd in clipvault wofi wl-copy gawk find; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        printf 'Error: required command not found: %s\n' "$cmd" >&2
        exit 1
    fi
done

# ImageMagick is optional. Without it, images are still usable, but won't be
# resized into thumbnails.
if command -v magick >/dev/null 2>&1; then
    HAVE_MAGICK=1
else
    HAVE_MAGICK=0
fi

# ---------------------------------------------------------------------------
# Cache
# ---------------------------------------------------------------------------

mkdir -p "$CACHE_DIR"

# ---------------------------------------------------------------------------
# Get clipboard contents
# ---------------------------------------------------------------------------

if ! list="$(clipvault list)"; then
    printf 'Error: clipvault list failed\n' >&2
    exit 1
fi

if [[ -z "$list" ]]; then
    exit 1
fi

# ---------------------------------------------------------------------------
# Remove stale thumbnails
# ---------------------------------------------------------------------------

# Build a list of image IDs currently present in clipvault.
declare -A valid_images=()

while IFS=$'\t' read -r id ext; do
    [[ -n "$id" ]] || continue
    valid_images["$id"]="$ext"
done < <(
    gawk '
        /^[0-9]+[[:space:]]+\[\[[[:space:]]binary/ {
            if (match($0,
                      /^([0-9]+)[[:space:]]+\[\[[[:space:]]binary.*(jpg|jpeg|png|bmp|webp|tif|tiff|gif)/,
                      m)) {
                print m[1] "\t" tolower(m[2])
            }
        }
    ' <<< "$list"
)

# Remove thumbnails whose IDs no longer exist.
while IFS= read -r -d '' thumbnail; do
    filename="${thumbnail##*/}"
    id="${filename%.*}"

    if [[ -z "${valid_images[$id]+x}" ]]; then
        rm -f -- "$thumbnail"
    fi
done < <(
    find "$CACHE_DIR" -type f -print0
)

# ---------------------------------------------------------------------------
# Generate Wofi entries
# ---------------------------------------------------------------------------

wofi_input="$(
    gawk \
        -v cache_dir="$CACHE_DIR" \
        -v thumb_size="$THUMB_SIZE" \
        -v have_magick="$HAVE_MAGICK" '
        # Ignore HTML metadata entries.
        /^[0-9]+[[:space:]]+<meta http-equiv=/ {
            next
        }

        # Image entry.
        /^[0-9]+[[:space:]]+\[\[[[:space:]]binary/ {
            if (match($0,
                      /^([0-9]+)[[:space:]]+\[\[[[:space:]]binary.*(jpg|jpeg|png|bmp|webp|tif|tiff|gif)/,
                      m)) {

                id  = m[1]
                ext = tolower(m[2])

                original = cache_dir "/" id "." ext
                thumb    = cache_dir "/" id ".thumb." ext

                # Get the image from clipvault if we do not have it cached.
                if (system("test -f " shellquote(original)) != 0) {
                    command = "printf \"%s\\n\" " shellquote(id) \
                              " | clipvault get > " shellquote(original)

                    if (system(command) != 0) {
                        system("rm -f -- " shellquote(original))
                        next
                    }
                }

                # Generate a real thumbnail.
                if (have_magick && system("test -f " shellquote(thumb)) != 0) {
                    command = "magick " shellquote(original) \
                              " -thumbnail " shellquote(thumb_size "x" thumb_size ">") \
                              " " shellquote(thumb) " 2>/dev/null"

                    if (system(command) != 0) {
                        system("rm -f -- " shellquote(thumb))
                    }
                }

                # Prefer the thumbnail when available.
                display_image = thumb

                if (system("test -f " shellquote(display_image)) != 0) {
                    display_image = original
                }

                # "text:" is what Wofi displays.
                # The actual clipboard ID remains the only value we care about.
                print "text:" id "\t:img:" display_image

                next
            }
        }

        # Normal text entry.
        {
            # Remove the leading ID from the display text.
            if (match($0, /^([0-9]+)[[:space:]]+(.*)$/, m)) {
                id   = m[1]
                text = m[2]

                # Keep the ID visible, but limit enormous clipboard entries.
                max = 120

                if (length(text) > max) {
                    text = substr(text, 1, max) "…"
                }

                print "text:" id "\t" text
                next
            }

            print $0
        }

        # Quote a string safely for the shell.
        function shellquote(s) {
            gsub(/\047/, "\047\\\\\047", s)
            return "\047" s "\047"
        }
    ' <<< "$list"
)"

if [[ -z "$wofi_input" ]]; then
    exit 1
fi

# ---------------------------------------------------------------------------
# Wofi
# ---------------------------------------------------------------------------

choice="$(
    printf '%s\n' "$wofi_input" |
        wofi \
            --dmenu \
            --insensitive \
            --prompt "Clipboard" \
            --width "$WOFI_WIDTH" \
            --define "image_size=$WOFI_IMAGE_SIZE" \
            --cache-file=/dev/null
)"

# Escape / close.
if [[ -z "$choice" ]]; then
    exit 1
fi

# ---------------------------------------------------------------------------
# Extract the clipvault ID
# ---------------------------------------------------------------------------

# Every generated entry starts with:
#
#   text:123
#
# so strip that first.
choice="${choice#text:}"

# Wofi may return the display text after a tab. We only want the ID.
choice="${choice%%$'\t'*}"

# Validate the ID before giving it to clipvault.
if [[ ! "$choice" =~ ^[0-9]+$ ]]; then
    printf 'Error: invalid clipvault ID: %s\n' "$choice" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Copy
# ---------------------------------------------------------------------------

if ! clipvault get "$choice" | wl-copy; then
    printf 'Error: failed to copy clipboard entry %s\n' "$choice" >&2
    exit 1
fi
