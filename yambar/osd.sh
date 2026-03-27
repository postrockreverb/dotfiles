#!/bin/sh
set -eu

FIFO="${XDG_RUNTIME_DIR:-/tmp}/yambar-osd.fifo"
TOKEN_DIR="${XDG_RUNTIME_DIR:-/tmp}/yambar-osd.tokens"

rm -f "$FIFO"
mkfifo "$FIFO"
mkdir -p "$TOKEN_DIR"

cleanup() {
    exec 3>&- || true
    rm -f "$FIFO"
    rm -rf "$TOKEN_DIR"
}
trap cleanup EXIT INT TERM

# Keep FIFO open read-write so EOF is not triggered when writers exit.
exec 3<>"$FIFO"

show_msg() {
    printf 'msg|string|%s\n\n' "$1"
}

clear_msg() {
    printf 'msg|string|\n\n'
}

# Clear stale text from a previous crashed instance.
clear_msg

current_token=""

while IFS= read -r msg <&3; do
    token="$(mktemp "$TOKEN_DIR/token.XXXXXX")"

    if [ -n "$current_token" ] && [ -e "$current_token" ]; then
        rm -f "$current_token"
    fi
    current_token="$token"

    show_msg "$msg"

    (
        sleep 1.5
        [ -e "$token" ] && clear_msg
        rm -f "$token"
    ) &
done
