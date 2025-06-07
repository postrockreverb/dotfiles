#!/bin/bash

theme=$1

case "$theme" in
zenbones | rose-pine) ;;
*)
  echo "Error: '$theme' is not allowed."
  exit 1
  ;;
esac

cat <<EOF >~/.config/kitty/theme.conf
env THEME=$theme

# kitty
include ./themes/$theme.conf

# bat
env BAT_THEME=$theme
EOF

bat cache --build
kitty @ load-config
