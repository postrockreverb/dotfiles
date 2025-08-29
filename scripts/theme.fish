set theme $argv[1]

switch $theme
    case 'zenbones' 'zenbones-light' 'rose-pine' 'rose-pine-dawn' 'xeno-pink'
        # Do nothing (allowed)
    case '*'
        echo "Error: '$theme' is not allowed."
        exit 1
end

echo "\
env THEME=$theme

# kitty
include ./themes/$theme.conf

# bat
env BAT_THEME=$theme
" > ~/.config/kitty/theme.conf

bat cache --build
kitty @ load-config

set -x THEME $theme
set -x BAT_THEME $theme
