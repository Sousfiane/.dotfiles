#!/bin/sh
if [ $(bluetoothctl show | grep "Powered: yes" | wc -c) -eq 0 ]
then
  echo "%{F#6e6a86} "
else
  if [ $(echo info | bluetoothctl | grep 'Device' | wc -c) -eq 31 ]
  then 
    echo "%{F#C4A7E7} "
  fi
  echo "%{F#f6c177} "
fi

