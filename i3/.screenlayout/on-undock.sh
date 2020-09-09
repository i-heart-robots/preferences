#!/bin/bash
xrandr --output DP-2-1 --off
sleep 4

xrandr --output DP-2-2 --off
sleep 4

xrandr --output eDP-1 --mode 1920x1080 --pos 0x0 --rotate normal \
       --output DP-2-1 --off
       --output DP-2-2 --off

xset r rate 200 30
