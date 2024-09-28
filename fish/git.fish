# git aliases

alias gl="git log"

alias ga="git add"

alias gp="git push"

alias gf="git fetch"

alias gc="git checkout"

alias gb="git branch"

alias gr="git rebase"
alias grc="git rebase --continue"
alias gra="git rebase --abort"
alias grm="git rebase origin/master"

alias gca="git commit --amend"
alias gcm="git commit -m"

alias gd="git diff"
alias gds="git diff --cached --stat"
alias gdn="git diff --name-only origin/master"
alias gda="git diff --cached --"

alias gclear="git clean -df && git checkout -- ."
alias gls="git for-each-ref --sort=committerdate ref/heads/ --format='%(committerdate:short) %(refname:short)'"
alias gprnm="git branch --merged | egrep -v '(^\*|master|dev|list)' | xargs git branch -d"

alias gs="git status"
