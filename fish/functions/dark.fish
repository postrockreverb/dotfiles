function dark -d "Set dark theme"
  set -xU theme "dark"
  kitty @ set-colors -a "~/.config/kitty/rose-pine.conf"
end
