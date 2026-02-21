complete -c theme -f -a "(grep 'case ' ~/.config/scripts/theme.fish | head -1 | grep -oE \"'[^']+\" | tr -d \"' \")"
