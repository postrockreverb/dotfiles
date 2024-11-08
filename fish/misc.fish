# misc aliases

alias fish_reload_rc="source ~/.config/fish/config.fish"

alias please "sudo"
alias m "make"
alias cat "bat --plain"
alias rm "trash"
alias reveal "open --reveal"
alias nterm "open . -a iterm"

# eza aliases
alias ll "eza --long --git --icons=always --no-user --no-permissions --no-time --group-directories-first"
alias lla "ll -a"

# broot aliases
alias br "broot"
alias brw "br -w"
alias mc "br -w"
alias brll "br -w -sdp"

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
alias rg rg
alias fd fd
