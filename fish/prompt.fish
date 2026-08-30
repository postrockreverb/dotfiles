function _git_branch_name
  echo (command git symbolic-ref HEAD 2> /dev/null | sed -e 's|^refs/heads/||')
end

function _is_git_dirty
  echo (command git status -s --ignore-submodules=dirty 2> /dev/null)
end

function _zmx_session_name
  set -q ZMX_SESSION; or return

  # zxc names sessions zxc-<id> and keeps the readable name in an alias
  # label, so prefer the label. Costs ~3ms against the ~30ms this prompt
  # already spends on git, so it is not worth caching.
  #
  # Read it from zmx list, which is tab separated: zmx get joins labels
  # with a space, so the alias in "alias=api ord=1" cannot be told apart
  # from one that itself contains a space. The row for the session you
  # are in - always this one - is marked with an arrow in place of the
  # leading indent, so that gets trimmed away too.
  for line in (command zmx list 2>/dev/null)
    set -l fields (string split \t -- (string trim -c ' →' -- $line))
    contains -- "name=$ZMX_SESSION" $fields; or continue

    for field in $fields
      if string match -q -- 'alias=*' $field
        string sub -s 7 -- $field
        return
      end
    end

    break
  end

  # Unlabelled sessions were made outside zxc; show them the way the
  # picker does, with $ZMX_SESSION_PREFIX stripped.
  if [ "$ZMX_SESSION_PREFIX" ]
    string replace -r '^'(string escape --style=regex -- $ZMX_SESSION_PREFIX) '' -- $ZMX_SESSION
    return
  end

  echo $ZMX_SESSION
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

  set -l zmx_session (_zmx_session_name)
  if [ "$zmx_session" ]
    set zmx_info "[$zmx_session] "
  end

  echo -n -s $zmx_info $cwd $git_info $normal ' ' $arrow ' '
end
