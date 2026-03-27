#!/bin/sh
set -eu

FIFO="${XDG_RUNTIME_DIR:-/tmp}/yambar-osd.fifo"
action="${1:?missing action}"

case "$action" in
    up)
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.01+ -l 1.0
        ;;
    down)
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.01-
        ;;
    mute)
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        ;;
    *)
        exit 1
        ;;
esac

status="$(wpctl get-volume @DEFAULT_AUDIO_SINK@)"
vol="$(printf '%s\n' "$status" | awk '{print int($2 * 100 + 0.5)}')"

if printf '%s\n' "$status" | grep -q '\[MUTED\]'; then
    msg="0*${vol}%"
else
    msg="${vol}%"
fi

printf '%s\n' "$msg" > "$FIFO"
