#!/bin/bash

case "$SRANDRD_ACTION" in
    "DP-2-1 connected") ~/.screenlayout/on-dock.sh;;
    "DP-2-1 disconnected") ~/.screenlayout/on-undock.sh;;
esac

xset r rate 200 30
