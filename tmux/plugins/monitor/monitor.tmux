#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$CURRENT_DIR/scripts/helpers.sh"

cpu_interpolation=(
  "\#{cpu_percentage}"
  "\#{cpu_icon}"
  "\#{cpu_bg_color}"
  "\#{cpu_fg_color}"
  "\#{ram_percentage}"
  "\#{ram_icon}"
  "\#{ram_bg_color}"
  "\#{ram_fg_color}"
  "\#{gpu_percentage}"
  "\#{gpu_bg_color}"
  "\#{gpu_fg_color}"
  "\#{battery_percentage}"
  "\#{battery_icon}"
  "\#{battery_remain}"
)
cpu_commands=(
  "#($CURRENT_DIR/scripts/cpu_percentage.sh)"
  "#($CURRENT_DIR/scripts/cpu_icon.sh)"
  "#($CURRENT_DIR/scripts/cpu_bg_color.sh)"
  "#($CURRENT_DIR/scripts/cpu_fg_color.sh)"
  "#($CURRENT_DIR/scripts/ram_percentage.sh)"
  "#($CURRENT_DIR/scripts/ram_icon.sh)"
  "#($CURRENT_DIR/scripts/ram_bg_color.sh)"
  "#($CURRENT_DIR/scripts/ram_fg_color.sh)"
  "#($CURRENT_DIR/scripts/gpu_percentage.sh)"
  "#($CURRENT_DIR/scripts/gpu_bg_color.sh)"
  "#($CURRENT_DIR/scripts/gpu_fg_color.sh)"
  "#($CURRENT_DIR/scripts/battery_percentage.sh)"
  "#($CURRENT_DIR/scripts/battery_icon.sh)"
  "#($CURRENT_DIR/scripts/battery_remain.sh)"
)

set_tmux_option() {
  local option=$1
  local value=$2
  @tmuxBin@/bin/tmux set-option -gq "$option" "$value"
}

do_interpolation() {
  local all_interpolated="$1"
  for ((i = 0; i < ${#cpu_commands[@]}; i++)); do
    all_interpolated=${all_interpolated//${cpu_interpolation[$i]}/${cpu_commands[$i]}}
  done
  echo "$all_interpolated"
}

update_tmux_option() {
  local option
  local option_value
  local new_option_value
  option=$1
  option_value=$(get_tmux_option "$option")
  new_option_value=$(do_interpolation "$option_value")
  set_tmux_option "$option" "$new_option_value"
}

main() {
  update_tmux_option "status-right"
  update_tmux_option "status-left"
  update_tmux_option "@catppuccin_cpu_text"
  update_tmux_option "@catppuccin_ram_text"
  update_tmux_option "@catppuccin_gpu_text"
  update_tmux_option "@catppuccin_battery_text"
  update_tmux_option "@catppuccin_battery_icon"
  update_tmux_option "@catppuccin_status_ram_text_fg"
  update_tmux_option "@catppuccin_status_ram_text_bg"
}
main
