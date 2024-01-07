#!/usr/bin/env bash

# Terminate already running bar instances
polybar-msg cmd quit

# Launch bar
echo "---" | tee -a /tmp/polybar1.log 
if type "xrandr"; then
  for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
    MONITOR=$m polybar --reload mybar &
  done
else
  polybar --reload mybar &
fi

# Launch arch_updates script
arch_updates & echo $! > ~/.config/polybar/scripts/arch/arch_updates.pid

echo "Bars launched..."


