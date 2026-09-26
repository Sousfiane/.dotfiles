#!/usr/bin/env bash

preview() {
    local file="$1"
    local dim="${FZF_PREVIEW_COLUMNS}x${FZF_PREVIEW_LINES}"

    case "$file" in
        *.png|*.jpg|*.jpeg|*.gif|*.webp|*.bmp|*.tiff|*.tif|*.avif|*.ico)
            kitten icat \
                --clear \
                --transfer-mode=memory \
                --unicode-placeholder \
                --stdin=no \
                --place="$dim@0x0" \
                "$file"
            ;;
        *)
            nvcat "$file"
            ;;
    esac
}

open_file() {
    local file="$1"

    case "$file" in
        *.png|*.jpg|*.jpeg|*.gif|*.webp|*.bmp|*.tiff|*.tif|*.avif|*.ico)
            exec zen-browser "$file"
            ;;
        *)
            exec nvim -- "$file"
            ;;
    esac
}

export -f preview

fzf_args=(
    --ansi
    --height=100%
    --layout=reverse
    --border
    --preview='bash -c '\''preview "$1"'\'' _ {}'
    --preview-label='alt-j/k: scroll'
    --preview-label-pos=bottom
    --preview-window='right:50%'
    --bind='alt-d:preview-half-page-down,alt-u:preview-half-page-up'
    --bind='alt-k:preview-up,alt-j:preview-down'
    --color='pointer:red,marker:red'
)

if [[ $PWD == "$HOME" ]]; then
    fd_args=(
        --type f
        --follow
        --search-path "$HOME"
        --search-path "$DOTFILES"
    )
else
    fd_args=(
        --type f
        --follow
    )
fi

selected=$(fd "${fd_args[@]}" | fzf "${fzf_args[@]}")

[[ -n $selected ]] || exit 0

open_file "$selected"
