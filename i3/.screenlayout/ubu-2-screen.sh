#!/bin/bash

xrandr --output DP-2-1 --mode 3440x1440 --pos 1920x0 --rotate normal \
       --output eDP-1 --mode 1920x1080 --pos 0x0 --rotate normal  \
       --off --output DP-1 --off --output DP-2 --off 

i3-msg workspace 1
i3-msg move workspace to output eDP-1

for i in {2..9}; do
    i3-msg workspace $i
    i3-msg move workspace to output DP-2-1
done

i3-msg workspace 2
i3-msg workspace 1

xset r rate 200 30

