#!/bin/bash

updates=$(checkupdates)
pkg_count=$(echo $updates | wc -w)
pkg_list=$(echo $updates)

echo "{\"text\":\"$pkg_count\", \"tooltip\":\"$pkg_list\"}"
