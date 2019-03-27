#!/bin/bash
xrandr --output eDP-1 --mode 1920x1080 --pos 0x0 --rotate normal \
       --output DP-2-1 --off
xset r rate 200 30
