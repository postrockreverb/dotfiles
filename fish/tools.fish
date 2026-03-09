# nvim aliases
alias v "nvim"
alias :Ex "nvim ."

# less aliases
alias less "less -r"

# make aliases
alias make "gmake"
alias m "make"

# mv aliases
alias mv "mv -iv"

# trash aliases
alias rm "trash"

# bat aliases
alias cat "bat --plain"

# eza aliases
alias ll "eza --long --icons=always --no-user --no-permissions --no-time --group-directories-first"
alias lla "ll -a"

# sleep aliases
alias sleep_in "sudo shutdown -s -q"
alias sleep_cancel "sudo pkill shutdown"

# battery aliases
alias blim "sudo bclm write 80"
alias bunlim "sudo bclm write 100"
alias bget "bclm read"

# reveal
function reveal
  set target $argv[1]
  if test -z "$target"
    set target .
  end

  if not test -d "$target"
    open --reveal "$target"
    return
  end

  set items "$target"/*
  if test (count $items) -gt 0
    open --reveal "$items[1]"
    return
  end

  open --reveal "$target"
end
