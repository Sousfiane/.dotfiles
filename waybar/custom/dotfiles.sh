#!/bin/bash

DOTFILES="$HOME/.dotfiles"

index=$(git -C "$DOTFILES" status -s)
index_count=$(printf "%s\n" "$index" | grep -c .)
index_list=${index//$'\n'/\\n}

printf '{"text":"%s","tooltip":"%s"}\n' "$index_count" "$index_list"

