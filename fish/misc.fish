# misc aliases

alias fish_reload_rc="source ~/.config/fish/config.fish"

alias please "sudo"
alias make "gmake"
alias m "make"
alias rm "trash"
alias reveal "open --reveal"

# bat aliases
set -xg BAT_THEME_DARK rose-pine
set -xg BAT_THEME_LIGHT rose-pine-dawn
alias cat "bat --plain"

# eza aliases
alias ll "eza --long --git --icons=always --no-user --no-permissions --no-time --group-directories-first"
alias lla "ll -a"

# sleep aliases
alias sleep_in "sudo shutdown -s"
alias sleep_cancel "sudo pkill shutdown"

# battery
alias blim "sudo bclm write 80"
alias bunlim "sudo bclm write 100"
alias bget "bclm read"

# ovpn aliases
alias vpn "please openvpn --config"
alias vpnj "please openvpn --config /usr/local/etc/openvpn/client.ovpn"

# other utilities
alias glow glow
alias rg rg
alias fd fd
