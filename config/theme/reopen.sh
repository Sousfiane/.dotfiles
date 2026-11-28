#!/usr/bin/env bash
# An app the theme closes (apply.sh: Zen, Spotify, Nautilus, which only take a new palette as they start)
# opens again where it was, silently: on the workspaces its windows were on, the workspace shown and the
# focus left as they are.
#
#   reopen.sh save <class>              before closing it: where its windows are (by title)
#   reopen.sh start <class> <command>   after: runs `command` (bash) with its windows held to the workspace
#                                       its last used one was on (hypr/config/reopen.lua), then, once they're
#                                       back, sends any other one to its own workspace by its title
#
# Without Hyprland, or with nothing saved, start only runs the command.

set -uo pipefail

state="${XDG_RUNTIME_DIR:-/tmp}/theme-reopen"
mkdir -p "$state"

# the windows of `class`: [{ title, ws }], the last used first
windows() {
    hyprctl clients -j 2>/dev/null | jq -c --arg c "$1" \
        '[.[] | select(.class == $c and .workspace.id > 0)] | sort_by(.focusHistoryID) | map({ title, ws: .workspace.id, address })' 2>/dev/null
}

lua() {
    hyprctl dispatch "function() $1 end" >/dev/null 2>&1
}

case ${1:-} in
save)
    class=$2
    windows "$class" >"$state/$class.json"
    ;;

start)
    class=$2 command=$3
    saved="$state/$class.json"
    before=$(cat "$saved" 2>/dev/null || echo '[]')
    rm -f "$saved"
    count=$(jq 'length' <<<"$before" 2>/dev/null || echo 0)
    if [[ -z ${HYPRLAND_INSTANCE_SIGNATURE:-} || $count -eq 0 ]]; then
        exec bash -c "$command"
    fi

    # every window to where the last used one was, held until they're back
    main_ws=$(jq '.[0].ws' <<<"$before")
    lua "require(\"config.reopen\").hold(\"$class\", $main_ws)"
    bash -c "$command" &

    # back: as many windows as before, or the number steady for 3 s; at most a minute (Spotify first applies
    # its theme)
    last=-1 steady=0
    for _ in $(seq 120); do
        sleep 0.5
        now=$(windows "$class" | jq 'length')
        if ((now >= count)); then
            break
        fi
        if ((now > 0 && now == last)); then
            steady=$((steady + 1))
            ((steady >= 6)) && break
        else
            steady=0
        fi
        last=$now
    done
    sleep 0.5

    # a window that was on another workspace, recognised by its title, goes back there
    while IFS= read -r w; do
        title=$(jq -r '.title' <<<"$w")
        ws=$(jq -r '.ws' <<<"$w")
        address=$(jq -r '.address' <<<"$w")
        want=$(jq -r --arg t "$title" 'map(select(.title == $t)) | .[0].ws // empty' <<<"$before")
        if [[ -n $want && $want != "$ws" ]]; then
            hyprctl dispatch "hl.dsp.window.move({ workspace = $want, window = \"address:$address\", follow = false })" >/dev/null
            # used: a second window with the same title goes where the next one was
            before=$(jq -c --arg t "$title" '(map(.title == $t) | index(true)) as $i | if $i then del(.[$i]) else . end' <<<"$before")
        fi
    done < <(windows "$class" | jq -c '.[]')

    lua "require(\"config.reopen\").release(\"$class\")"
    ;;

*)
    echo "usage: reopen.sh save <class> | start <class> <command>" >&2
    exit 1
    ;;
esac
