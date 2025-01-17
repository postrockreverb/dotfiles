set fish_greeting ""

set HOMEBREW_AUTO_UPDATE_SECS 1209600 # two weeks

if test "$TERM" = "xterm-kitty"
  alias ssh="kitty +kitten ssh"
end

alias v "nvim"
alias t "tmux"
alias ta "tmux attach"

alias lv "/Users/yermac/.local/bin/lvim"

source ~/.config/fish/prompt.fish
source ~/.config/fish/ssh.fish
source ~/.config/fish/git.fish
source ~/.config/fish/pls.fish
source ~/.config/fish/misc.fish

zoxide init fish | source

if status is-interactive
    # Commands to run in interactive sessions can go here
    # clear && neofetch
end
