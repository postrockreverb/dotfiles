# Completions for zxc (~/.config/scripts/zxc.fish).
#
# --complete emits "display name<TAB>start dir" for every live session,
# honouring $ZMX_SESSION_PREFIX and showing renamed sessions under their
# new name. A name that matches nothing becomes a new session, so an
# unrecognised argument is not an error.

complete -c zxc -f -n __fish_is_first_arg -a "(~/.config/scripts/zxc.fish --complete)"

# Anything after the session name is the command to run in it. The skip
# covers `zxc` and the session name, so the next token completes as a
# command and the ones after it as that command's arguments.
complete -c zxc -x -n 'not __fish_is_first_arg' -a "(__fish_complete_subcommand --fcs-skip=2)"
