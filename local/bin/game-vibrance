#!/usr/bin/env bash

set -e

NVIBRANT="/usr/bin/nvibrant"

# Your physical NVIDIA outputs:
#
# 0 = HDMI
# 1 = DP  <- gaming monitor
# 2 = DP
# 3 = DP
# 4 = DP
# 5 = DP
# 6 = DP

NORMAL=(0 0 0 0 0 0 0)
GAMING=(0 512 0 0 0 0 0)

restore() {
    echo "Restoring normal vibrance..."
    "$NVIBRANT" "${NORMAL[@]}" >/dev/null
}

trap restore EXIT INT TERM

echo "Setting gaming vibrance..."
"$NVIBRANT" "${GAMING[@]}"

echo "Launching game..."
"$@"
