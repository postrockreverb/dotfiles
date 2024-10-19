function light -d "Set light theme"
  set -xU theme "light"
  kitty @ set-colors -a "~/.config/kitty/rose-pine-dawn.conf"
end
