#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <input> <output>"
  exit 1
fi

in="$1"
out="$2"

magick "$in" \
  -colorize 0,6,8 \
  -modulate 95,60,95 \
  -ordered-dither o8x8,8 \
  -contrast-stretch 4x4 \
  -blur 0x0.5 \
  -unsharp 0x0.7 \
  "$out"
