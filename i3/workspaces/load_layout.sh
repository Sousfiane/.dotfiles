#!/bin/sh
i3-msg "workspace 1; append_layout ~/.config/i3/workspaces/workspace_1.json"

(xfce4-terminal --hold -e neofetch &)
(xfce4-terminal --hold -e peaclock &)

