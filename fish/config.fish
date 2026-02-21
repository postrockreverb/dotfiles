set fish_greeting ""

set PATH $PATH ~/.local/bin

set -x XDG_CONFIG_HOME "$HOME/.config"
set HOMEBREW_AUTO_UPDATE_SECS 1209600 # two weeks

if test "$TERM" = "xterm-kitty"
  alias kssh="kitty +kitten ssh"
end

function theme; source ~/.config/scripts/theme.fish $argv; end
alias fish_reload_rc="source ~/.config/fish/config.fish"
alias brew_bundle="brew bundle --file=~/.config/brew/Brewfile"
alias brew_bundle_export="brew bundle dump --file=\"~/.config/brew/Brewfile\" --force"

source ~/.config/fish/prompt.fish
source ~/.config/fish/git.fish
source ~/.config/fish/tools.fish

if test -f ~/.config/fish/local.fish
  source ~/.config/fish/local.fish
end

zoxide init fish | source

if status is-interactive
    # Commands to run in interactive sessions can go here
end
