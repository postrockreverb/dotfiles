#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 [-a|--activate] [-s|--screen WxH] <input> <output>"
  echo "  -a, --activate  add an \"Activate Linux\" watermark (font: \$WATERMARK_FONT or Segoe UI)"
  echo "  -s, --screen    screen size in points the wallpaper is shown on with \"Fill Screen\" (default: 1512x982)"
  exit 1
}

activate=0
screen=1512x982
args=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -a|--activate) activate=1 ;;
    -s|--screen) [[ $# -ge 2 ]] || usage; screen="$2"; shift ;;
    -h|--help) usage ;;
    *) args+=("$1") ;;
  esac
  shift
done
[[ ${#args[@]} -eq 2 && "$screen" =~ ^[0-9]+x[0-9]+$ ]] || usage

in="${args[0]}"
out="${args[1]}"

watermark=()
if [[ $activate -eq 1 ]]; then
  # Windows uses Segoe UI; Selawik is Microsoft's metric-compatible open fallback
  font="${WATERMARK_FONT:-}"
  if [[ -z "$font" ]]; then
    fonts=$(magick -list font | sed -n 's/^ *Font: //p')
    for f in Segoe-UI SegoeUI Selawik Helvetica Arial; do
      if grep -qx "$f" <<<"$fonts"; then font="$f"; break; fi
    done
  fi

  # Layout in screen points, as on Windows 10 at 100% scaling: text starts 335pt
  # from the right edge, title/subtitle tops 135pt/100pt above the bottom edge.
  # "Fill Screen" scales the image to cover the screen and crops the overflow
  # equally from both sides, so map screen points back into image pixels.
  read -r w h <<<"$(magick identify -format '%w %h' "$in[0]")"
  read -r x y1 y2 p1 p2 < <(awk -v w="$w" -v h="$h" -v sw="${screen%x*}" -v sh="${screen#*x}" 'BEGIN {
    f = sw / w > sh / h ? sw / w : sh / h
    ox = (w - sw / f) / 2; oy = (h - sh / f) / 2
    printf "%.0f %.0f %.0f %.0f %.0f\n", ox + (sw - 335) / f, oy + (sh - 135) / f, oy + (sh - 100) / f, 24 / f, 15 / f
  }')

  watermark=(
    -gravity NorthWest -font "$font" -fill 'rgba(255,255,255,0.5)'
    -pointsize "$p1" -annotate "+$x+$y1" 'Activate Linux'
    -pointsize "$p2" -annotate "+$x+$y2" 'Go to Settings to activate Linux.'
  )
fi

magick "$in" \
  -colorize 0,6,8 \
  -modulate 95,60,95 \
  -ordered-dither o8x8,8 \
  -contrast-stretch 4x4 \
  -blur 0x0.5 \
  -unsharp 0x0.7 \
  ${watermark[@]+"${watermark[@]}"} \
  "$out"
