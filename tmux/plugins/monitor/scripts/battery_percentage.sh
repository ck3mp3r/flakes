#!/usr/bin/env bash
# Wrapper that calls the nixpkgs battery plugin script
exec @tmuxPluginsBattery@/share/tmux-plugins/battery/scripts/battery_percentage.sh
