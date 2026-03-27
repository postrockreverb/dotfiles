#!/bin/sh
set -eu

FIFO="${XDG_RUNTIME_DIR:-/tmp}/yambar-osd.fifo"

action="${1:?missing action}"

case "$action" in
    up)
        brightnessctl --class=backlight set +1% >/dev/null
        ;;
    down)
        brightnessctl --class=backlight set 1%- >/dev/null
        ;;
    *)
        exit 1
        ;;
esac

percent="$(
    brightnessctl --class=backlight -m | awk -F, '{gsub(/%/,"",$4); print $4}'
)"

printf '%s%%\n' "$percent" > "$FIFO"
