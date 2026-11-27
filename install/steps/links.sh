#!/usr/bin/env bash
# The symlinks. Where a file goes is where it sits in the repo:
#
#   config/<app>/<entry>      → ~/.config/<app>/<entry>
#   home/<name>               → ~/.<name>
#   local/<folder>/<entry>    → ~/.local/<folder>/<entry>
#
# One level deep: a subfolder is a single link, so files added inside it are live at once; a new entry at
# the top of an app folder needs this step again. Entries starting with "." (editor files like .luarc.json)
# aren't linked, nor what git ignores (Python's __pycache__ next to a script in local/bin), and what an app
# writes into its own config folder stays out of the repo.
#
# Safe to re-run: a correct link is left alone, a link into the repo that's outdated or broken is replaced,
# and a real file is never touched without asking. Links left broken by files removed from the repo go.

source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

# whether `entry` belongs in the links: not something git ignores (a cache written next to a script)
tracked() {
    [[ -e $1 ]] && ! git -C "$DOTFILES" check-ignore -q -- "$1"
}

# every link the layout asks for, as "source<TAB>target" (bash's * skips dot entries)
plan() {
    local app dir entry
    for app in "$DOTFILES"/config/*/; do
        app=${app%/}
        for entry in "$app"/*; do
            tracked "$entry" && printf '%s\t%s\n' "$entry" "$HOME/.config/${app##*/}/${entry##*/}"
        done
    done
    for entry in "$DOTFILES"/home/*; do
        tracked "$entry" && printf '%s\t%s\n' "$entry" "$HOME/.${entry##*/}"
    done
    for dir in "$DOTFILES"/local/*/; do
        dir=${dir%/}
        for entry in "$dir"/*; do
            tracked "$entry" && printf '%s\t%s\n' "$entry" "$HOME/.local/${dir##*/}/${entry##*/}"
        done
    done
    return 0
}

# ---------- a real file in the way ----------

answer_all=""        # set by an uppercase answer: applies to every conflict after it
action=""            # what resolve decided

# what to do with `dst`: skip, backup or overwrite. Any other key skips, so nothing is lost by accident
resolve() {
    local dst=$1 key
    if [[ -n $answer_all ]]; then
        action=$answer_all
        return
    fi
    user "${dst/#$HOME/\~} already exists and isn't a link. [s]kip, [b]ackup, [o]verwrite? (S/B/O: the same for all)"
    read -r -n 1 key </dev/tty
    echo
    case $key in
        b) action=backup ;;
        o) action=overwrite ;;
        S) action=skip answer_all=skip ;;
        B) action=backup answer_all=backup ;;
        O) action=overwrite answer_all=overwrite ;;
        *) action=skip ;;
    esac
}

# deals with something that isn't ours at `dst`; fails when it stays where it is
conflict() {
    local dst=$1
    resolve "$dst"
    case $action in
        skip)
            warn "skipped ${dst/#$HOME/\~} (left as it is)"
            skipped=$((skipped + 1))
            return 1
            ;;
        backup)
            local backup="$dst.backup"
            [[ -e $backup || -L $backup ]] && backup="$dst.backup.$(date +%Y%m%d%H%M%S)"
            mv "$dst" "$backup"
            info "moved ${dst/#$HOME/\~} to ${backup/#$HOME/\~}"
            ;;
        overwrite)
            rm -rf "$dst"
            info "removed ${dst/#$HOME/\~}"
            ;;
    esac
}

# ---------- one link ----------

linked=0 kept=0 skipped=0

link() {
    local src=$1 dst=$2 current parent

    # the folder it goes in is itself a link into the repo (an older layout linked whole app folders): `dst`
    # is then the repo's own file, which must never be moved or deleted. The folder link goes, and a real
    # folder takes its place
    parent=$(dirname "$dst")
    if [[ -L $parent && $(readlink -f "$parent") == "$DOTFILES"/* ]]; then
        rm "$parent"
        info "removed ${parent/#$HOME/\~} (a link to a whole folder of the dotfiles, from an older layout)"
    fi
    # any other way `dst` could still be a file of the repo: leave it alone
    if [[ ! -L $dst && -e $dst && $(realpath "$dst") == "$DOTFILES"/* ]]; then
        warn "skipped ${dst/#$HOME/\~}: it's a file of the dotfiles itself (a folder above it links into them)"
        skipped=$((skipped + 1))
        return 0
    fi

    if [[ -L $dst ]]; then
        current=$(readlink "$dst")
        if [[ $current == "$src" ]]; then
            kept=$((kept + 1))
            return 0
        fi
        if [[ $current == "$DOTFILES"/* || ! -e $dst ]]; then
            rm "$dst"            # ours from an older layout, or broken: just replace it
        else
            conflict "$dst" || return 0
        fi
    elif [[ -e $dst ]]; then
        conflict "$dst" || return 0
    fi

    mkdir -p "$(dirname "$dst")"
    ln -s "$src" "$dst"
    success "linked ${dst/#$HOME/\~}"
    linked=$((linked + 1))
}

# ---------- links the repo no longer has ----------

clean() {
    local l
    while IFS= read -r -d '' l; do
        [[ $(readlink "$l") == "$DOTFILES"/* ]] || continue
        rm "$l"
        info "removed broken link ${l/#$HOME/\~}"
    done < <(
        find "$HOME" -maxdepth 1 -xtype l -print0
        find "$HOME/.config" "$HOME/.local" -mindepth 2 -maxdepth 2 -xtype l -print0 2>/dev/null
    )
    return 0
}

# ---------- run ----------

while IFS=$'\t' read -r src dst; do
    link "$src" "$dst"
done < <(plan)

clean

summary="$linked linked, $kept already in place"
[[ $skipped -gt 0 ]] && summary+=", $skipped skipped"
success "$summary"
