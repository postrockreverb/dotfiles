function _git_branch_name
  echo (command git symbolic-ref HEAD 2> /dev/null | sed -e 's|^refs/heads/||')
end

function _is_git_dirty
  echo (command git status -s --ignore-submodules=dirty 2> /dev/null)
end

function fish_prompt
  set -l blue (set_color blue)
  set -l green (set_color green)
  set -l normal (set_color normal)

  set -l arrow "λ"
  set -l cwd $blue(basename (prompt_pwd))

  set -l git_branch (_git_branch_name)
  if [ "$git_branch" ]
    set git_info "$green$git_branch"
    set git_info ":$git_info"

    if [ (_is_git_dirty) ]
      set -l dirty "*"
      set git_info "$git_info$dirty"
    end
  end

  if set -q ZMX_SESSION
    set zmx_info "[$ZMX_SESSION] "
  end

  echo -n -s $zmx_info $cwd $git_info $normal ' ' $arrow ' '
end
