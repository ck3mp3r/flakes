#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$CURRENT_DIR/helpers.sh"

gpu_percentage_format="%3.1f%%"

print_gpu_percentage() {
  gpu_percentage_format=$(get_tmux_option "@gpu_percentage_format" "$gpu_percentage_format")

  if is_osx; then
    # Use ioreg to get Metal GPU usage from IOAccelerator
    usage=$(cached_eval ioreg -r -d 1 -w 0 -c IOAccelerator | grep -E '"Device Utilization %"' | sed 's/.*"Device Utilization %"=\([0-9]*\).*/\1/')
    if [ -n "$usage" ] && [ "$usage" -ge 0 ] 2>/dev/null; then
      # shellcheck disable=SC2059
      printf "$gpu_percentage_format" "$usage"
    else
      echo "N/A"
    fi
  elif is_linux; then
    if command_exists "nvidia-smi"; then
      cached_eval nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | awk -v format="$gpu_percentage_format" '{printf(format, $1)}'
    elif command_exists "radeontop"; then
      # For AMD GPUs on Linux
      usage=$(cached_eval radeontop -d - -l 1 | grep -o 'gpu [0-9.]*%' | awk '{print $2}' | sed 's/%//')
      if [ -n "$usage" ]; then
        # shellcheck disable=SC2059
        printf "$gpu_percentage_format" "$usage"
      else
        echo "N/A"
      fi
    else
      echo "N/A"
    fi
  else
    echo "N/A"
  fi
}

main() {
  print_gpu_percentage
}
main
