#!/bin/sh
xrandr --output DP-2-1 --off
sleep 4

xrandr --output DP-2-2 --off
sleep 4

xrandr --output DP-2-1 --mode 3840x1600 --pos 1920x216 --rotate normal \
       --output DP-2-2 --mode 2560x1440 --pos 5760x0 --rotate right \
       --output DP-2-3 --off \
       --output eDP-1 --primary --mode 1920x1080 --pos 0x736 --rotate normal \
       --output HDMI-2 --off \
       --output HDMI-1 --off \
       --output DP-2 --off \
       --output DP-1 --off

sleep 13

i3-msg workspace 1
i3-msg move workspace to output eDP-1

for i in {2..5}; do
    i3-msg workspace $i
    i3-msg move workspace to output DP-2-1
done

for i in {6..10}; do
    i3-msg workspace $i
    i3-msg move workspace to output DP-2-2
done

i3-msg workspace 6
i3-msg workspace 2
i3-msg workspace 1

xset r rate 200 30
