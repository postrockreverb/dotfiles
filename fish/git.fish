# git aliases

alias g="lazygit"

alias ga="git add"

alias gp="git push"
alias gpf="git push -f"

alias gf="git fetch"
alias gfm="git fetch origin master"

alias gc="git checkout"

alias gb="git branch"

alias gr="git rebase"
alias grc="git rebase --continue"
alias gra="git rebase --abort"
alias grm="git rebase origin/master"

alias gch="git cherry-pick"
alias gchc="git cherry-pick --continue"
alias gcha="git cherry-pick --abort"

alias gca="git commit --amend"
alias gcm="git commit -m"

alias gd="git diff"
alias gda="git diff --cached --"
alias gds="git diff --cached --stat"
alias gdn="git diff --name-only origin/master"

alias gs="git status"
alias gl="git log --graph --pretty=format:\"%C(red)%h%C(reset)%C(yellow)%d%Creset %s %C(green italic)(%cr)%C(reset) %C(blue)%an%C(reset) %C(white dim)%GK %C(reset)\""

alias gcls="git clean -df && git checkout -- ."
alias gprunemegred="git branch --merged | egrep -v '(^\*|master|dev|list)' | xargs git branch -d"

# Interactive git staging with fzf.
function tgs
  git --no-optional-locks status --porcelain=v1 | sed -E 's/^(.)(.) /\1 \2  /' | \
    fzf \
      --ansi \
      --info=inline-right \
      --height=100% \
      --layout=reverse \
      --border=none \
      --pointer="" \
      --preview-window='up,60%,border-none' \
      --preview 'cd (git rev-parse --show-toplevel); set f (string sub -s 6 -- {}); begin; git diff --cached -- "$f"; git diff -- "$f"; end | delta --color-only --line-numbers --line-numbers-left-format=\'\' --line-numbers-right-format=\'{np:>4} \' --detect-dark-light=never --paging=never --width=$FZF_PREVIEW_COLUMNS' \
      --header="+ -  <left> to stage | <right> to unstage | <ctrl-x> to reset" \
      --bind 'left:execute-silent(cd (git rev-parse --show-toplevel); git add -- (string sub -s 6 -- {}))+reload(git --no-optional-locks status --porcelain=v1 | sed -E "s/^(.)(.) /\1 \2  /")' \
      --bind 'right:execute-silent(cd (git rev-parse --show-toplevel); git restore --staged -- (string sub -s 6 -- {}))+reload(git --no-optional-locks status --porcelain=v1 | sed -E "s/^(.)(.) /\1 \2  /")' \
      --bind 'ctrl-x:execute-silent(cd (git rev-parse --show-toplevel); git restore --staged --worktree -- (string sub -s 6 -- {}))+reload(git --no-optional-locks status --porcelain=v1 | sed -E "s/^(.)(.) /\1 \2  /")' \
      --bind 'ctrl-d:preview-half-page-down' \
      --bind 'ctrl-u:preview-half-page-up' \
      --bind 'ctrl-f:change-preview-window(up,99%,border-none|hidden|up,60%,border-none)'
end

# Interactive git branch switcher with fzf.
function tgb
  git branch --format='%(refname:short)' | \
    fzf \
      --ansi \
      --info=inline-right \
      --height=100% \
      --layout=reverse \
      --border=none \
      --pointer="" \
      --preview-window='up,60%,border-none' \
      --header="<enter> browse commits | <alt-enter> checkout" \
      --preview 'git log --graph --color=always --pretty=format:"%C(red)%h%C(reset)%C(yellow)%d%Creset %s %C(green italic)(%cr)%C(reset) %C(blue)%an%C(reset)" {}' \
      --bind 'alt-enter:become(git checkout {})' \
      --bind 'enter:execute(fish -c "source $HOME/.config/fish/git.fish; tgl {}")' \
      --bind 'ctrl-d:preview-half-page-down' \
      --bind 'ctrl-u:preview-half-page-up' \
      --bind 'ctrl-f:change-preview-window(up,99%,border-none|hidden|up,60%,border-none)'
end

# Interactive commit browser with fzf.
function tgl
  git log --color=always --format='%h  %s  %C(green)%cr%C(reset)  %C(blue)%an%C(reset)' $argv | \
    fzf \
      --ansi \
      --info=inline-right \
      --height=100% \
      --layout=reverse \
      --border=none \
      --pointer="" \
      --preview-window='up,60%,border-none' \
      --header="<enter> browse commit" \
      --preview "git show {1} | delta --color-only --line-numbers --line-numbers-left-format='' --line-numbers-right-format='{np:>4} ' --detect-dark-light=never --paging=never --width=\$FZF_PREVIEW_COLUMNS" \
      --bind 'enter:execute(fish -c "source $HOME/.config/fish/git.fish; tgshow {1}")' \
      --bind 'ctrl-d:preview-half-page-down' \
      --bind 'ctrl-u:preview-half-page-up' \
      --bind 'ctrl-f:change-preview-window(up,99%,border-none|hidden|up,60%,border-none)'
end

# Interactive per-hunk viewer for a single commit. Opened from tgl's <enter>.
function tgshow
  # Default to HEAD; an empty $commit would collapse the concatenated --preview
  # string to nothing (fish: string × empty-list = empty), breaking fzf's args.
  set -l commit HEAD
  test -n "$argv[1]"; and set commit $argv[1]
  # One fzf row per hunk. Hidden fields drive the preview: 1 = file, 2 = the
  # scroll target = new-file start line + deletions above it in the same file
  # (the full-context diff below adds one output row per removed line). Field 3
  # on is the visible table (file, old range, new range, section heading), each
  # column padded to its widest value (two-pass) so the rows line up.
  set -l list '/^diff --git/{file=$NF;sub(/^b\//,"",file);fdel=0;h=1;next} h{if($0 ~ /^@@/){h=0}else{next}} /^@@/{i++;f[i]=file;o[i]=$2;nw[i]=$3;split($3,a,",");st=a[1];sub(/^\+/,"",st);scroll[i]=st+fdel;hd=$0;sub(/^@@ [^ ]+ [^ ]+ @@ ?/,"",hd);s[i]=hd;if(length(file)>wf)wf=length(file);if(length($2)>wo)wo=length($2);if(length($3)>wn)wn=length($3);next} /^-/{if($0 !~ /^---/)fdel++} END{for(j=1;j<=i;j++)printf "%s\t%d\t%-*s  %-*s  %-*s  %s\n",f[j],scroll[j],wf,f[j],wo,o[j],wn,nw[j],s[j]}'
  # Preview: the file rendered as a full-context diff (color-only, matching tgl),
  # so every +/- line is visible in place. cd to the repo root first because the
  # `-- {1}` pathspec is resolved from cwd but paths are root-relative. delta
  # keeps the raw diff headers, so the current hunk lands a few rows below the
  # top; the scroll slack absorbs it. Single-quoted so cd/placeholders stay
  # literal for the fzf preview shell; \' are the line-number format quotes.
  set -l preview 'cd (git rev-parse --show-toplevel); git show --format= -U100000 '$commit' -- {1} | delta --color-only --line-numbers --line-numbers-left-format=\'\' --line-numbers-right-format=\'{np:>4} \' --detect-dark-light=never --paging=never --width=$FZF_PREVIEW_COLUMNS'

  git show --format= $commit | awk $list | \
    fzf \
      --ansi \
      --info=inline-right \
      --height=100% \
      --layout=reverse \
      --border=none \
      --pointer="" \
      --delimiter='\t' \
      --with-nth='3..' \
      --preview-window='up,60%,border-none,+{2}-3' \
      --preview $preview \
      --bind 'ctrl-d:preview-half-page-down' \
      --bind 'ctrl-u:preview-half-page-up' \
      --bind 'ctrl-f:change-preview-window(up,99%,border-none|hidden|up,60%,border-none)'
end

# Interactive commit history for a file: the commits that changed it.
function tgblame
  if test -z "$argv[1]"
    echo "usage: tgblame <file>"
    return 1
  end
  set -l file $argv[1]
  git log --follow --color=always --format='%h  %s  %C(green)%cr%C(reset)  %C(blue)%an%C(reset)' -- $file | \
    fzf \
      --ansi \
      --info=inline-right \
      --height=100% \
      --layout=reverse \
      --border=none \
      --pointer="" \
      --preview-window='up,60%,border-none' \
      --header="<enter> browse commit" \
      --preview 'git show {1} -- '$file' | delta --color-only --line-numbers --line-numbers-left-format=\'\' --line-numbers-right-format=\'{np:>4} \' --detect-dark-light=never --paging=never --width=$FZF_PREVIEW_COLUMNS' \
      --bind 'enter:execute(fish -c "source $HOME/.config/fish/git.fish; tgshow {1}")' \
      --bind 'ctrl-d:preview-half-page-down' \
      --bind 'ctrl-u:preview-half-page-up' \
      --bind 'ctrl-f:change-preview-window(up,99%,border-none|hidden|up,60%,border-none)'
end
