# git aliases

alias g="lazygit"

alias ga="git add"

alias gp="git push"
alias gpf="git push -f"

alias gf="git fetch"

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
alias gls="git for-each-ref --sort=committerdate ref/heads/ --format='%(committerdate:short) %(refname:short)'"

alias gcls="git clean -df && git checkout -- ."
alias gprunemegred="git branch --merged | egrep -v '(^\*|master|dev|list)' | xargs git branch -d"
