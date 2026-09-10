#!/usr/bin/env fish

# zxc - fzf picker for zmx sessions.
#
#   zxc              open the picker
#   zxc <name>       attach to <name>, creating it if needed
#   zxc <name> <cmd> same, running <cmd> instead of a shell
#
# zmx cannot rename a live session, so zxc keeps the human name in an
# `alias` label and gives the session itself an opaque zxc-<id>. The
# label is the only name zxc ever shows, and a rename only touches the
# label. Sessions created outside zxc have no label and appear under
# their real name.
#
# The script doubles as its own helper: fzf runs binds and the preview
# through sh, which cannot see fish functions, so they re-invoke it. The
# completions in ~/.config/fish/completions/zxc.fish call --complete.

set -g _zxc_script (path resolve (status filename))

function _zxc_shquote
    # sh-safe single quoting; stands in for bash's printf %q, which
    # fish's printf does not implement.
    printf "'%s'" (string replace -a -- "'" "'\\''" "$argv[1]")
end

function _zxc_exists
    # zmx get exits non-zero for a session that is not up, whether or
    # not it has any labels.
    ZMX_SESSION_PREFIX= zmx get "$argv[1]" >/dev/null 2>&1
end

function _zxc_display
    # The name a session goes by. Read from zmx list, which is tab
    # separated: zmx get joins labels with a space, so the alias in
    # "alias=api ord=1" cannot be told apart from one containing a space.
    for line in (_zxc_sessions)
        set -l parts (string split \t -- $line)

        if test "$parts[1]" = "$argv[1]"
            echo "$parts[2]"
            return 0
        end
    end

    return 1
end

function _zxc_cwds
    # "pid<TAB>cwd" for each pid that still has a process. A session's
    # start_dir is only where it began; the shell inside it cds, and
    # macOS has no /proc, so lsof is the only way to read that. One
    # batched call covers the whole list in a few ms.
    test (count $argv) -gt 0; or return

    set -l pid ""

    lsof -a -d cwd -p (string join , $argv) -Fpn 2>/dev/null | while read -l line
        set -l value (string sub -s2 -- $line)

        switch (string sub -l1 -- $line)
            case p
                set pid $value
            case n
                test -n "$pid"; or continue

                printf '%s\t%s\n' $pid $value
                set pid ""
        end
    end
end

function _zxc_sessions
    # One "name<TAB>display<TAB>dir" row per session, filtered by
    # $ZMX_SESSION_PREFIX. The picker, name resolution and completions
    # all read this, so they agree on what a session is called.
    set -l prefix "$ZMX_SESSION_PREFIX"
    set -l rows
    set -l pids

    # Each zmx list line is tab-separated k=v fields: name, pid, clients,
    # created, start_dir, then optional ones (ended, exit_code, cmd) and
    # any session labels. Parse by key, since the optional fields shift
    # everything after them.
    zmx list 2>/dev/null | while read -l line
        set -l name ""
        set -l dir ""
        set -l pid ""
        set -l alias ""
        set -l ord ""
        set -l created 0

        for field in (string split \t -- $line)
            # zmx list marks the session you are currently in with an
            # arrow in place of the leading indent, so strip that too or
            # the row you are sitting in drops out of the list.
            set -l kv (string split -m1 = -- (string trim -c ' →' -- $field))
            test (count $kv) -eq 2; or continue

            switch $kv[1]
                case name
                    set name $kv[2]
                case start_dir
                    set dir $kv[2]
                case pid
                    set pid $kv[2]
                case alias
                    set alias $kv[2]
                case ord
                    set ord $kv[2]
                case created
                    set created $kv[2]
            end
        end

        test -n "$name"; or continue

        set -l display "$name"

        if test -n "$prefix"
            if not string match -q -- "$prefix*" "$name"
                continue
            end

            set display (
                string sub \
                    -s (math (string length -- "$prefix") + 1) \
                    -- "$name"
            )
        end

        if test -n "$alias"
            set display "$alias"
        end

        # Sessions you have not placed float above the placed ones,
        # newest first, so one you just created is at the top until you
        # arrange the list. 9999999999 - created inverts the timestamp
        # into a descending key.
        set -l key (printf '0:%010d' (math 9999999999 - $created))

        if test -n "$ord"
            set key (printf '1:%06d' $ord)
        end

        # Buffered rather than piped straight into sort: the cwds are
        # worth one lsof call for the whole list, and that needs every
        # pid up front.
        set -a rows (printf '%s\t%s\t%s\t%s\t%s' "$key" "$name" "$display" "$pid" "$dir")
        set -a pids $pid
    end

    test (count $rows) -gt 0; or return

    set -l cwd_pids
    set -l cwd_dirs

    for line in (_zxc_cwds $pids)
        set -l parts (string split \t -- $line)

        set -a cwd_pids $parts[1]
        set -a cwd_dirs $parts[2]
    end

    for row in $rows
        set -l parts (string split \t -- $row)

        # A session whose process has ended has no cwd to read, so it
        # keeps showing the directory it started in.
        set -l dir $parts[5]
        set -l i (contains -i -- "$parts[4]" $cwd_pids)

        test -n "$i"; and set dir $cwd_dirs[$i]

        printf '%s\t%s\t%s\t%s\n' $parts[1] $parts[2] $parts[3] "$dir"
    end | LC_ALL=C sort -t\t -k1,1 -s | cut -f2-
end

function _zxc_candidates
    # fzf aligns nothing itself, so pad here and keep display+dir as a
    # single field. Field 1 is the complete session name, hidden by
    # --with-nth, so {1} always names something zmx can resolve.
    _zxc_sessions | while read -l -d \t name display dir
        # Shortened for the eye only. Everything that acts on a
        # directory reads _zxc_sessions, which keeps it absolute.
        set -l pretty "$dir"

        if string match -q -- "$HOME" "$dir"; or string match -q -- "$HOME/*" "$dir"
            set pretty '~'(
                string sub -s (math (string length -- "$HOME") + 1) -- "$dir"
            )
        end

        printf '%s\t%-20s  %s\n' "$name" "$display" "$pretty"
    end
end

function _zxc_complete
    # fish completion format: value<TAB>description.
    for line in (_zxc_sessions)
        set -l parts (string split \t -- $line)
        test (count $parts) -ge 3; or continue

        printf '%s\t%s\n' "$parts[2]" "$parts[3]"
    end
end

function _zxc_resolve
    # Map a name someone typed onto a real zmx session name. Displayed
    # names are tried first, so a generated id can never shadow the name
    # a session actually goes by.
    set -l wanted "$argv[1]"
    set -l rows (_zxc_sessions)

    for field in 2 1
        for line in $rows
            set -l parts (string split \t -- $line)
            test (count $parts) -ge 2; or continue

            if test "$parts[$field]" = "$wanted"
                echo "$parts[1]"
                return 0
            end
        end
    end

    return 1
end

function _zxc_new_id
    # Opaque on purpose: the zmx name is fixed for the session's life, so
    # keeping the human name out of it means a rename never lies.
    while true
        set -l id zxc-(printf '%06x' (random 0 16777215))

        if not _zxc_exists "$ZMX_SESSION_PREFIX$id"
            echo $id
            return
        end
    end
end

function _zxc_label_when_ready
    set -l real $argv[1]
    set -l name $argv[2]

    # Gives up after ~5s, which only happens if the session never came up.
    for i in (seq 100)
        if _zxc_exists "$real"
            ZMX_SESSION_PREFIX= zmx set "$real" "alias=$name"
            return
        end

        sleep 0.05
    end
end

function _zxc_create
    set -l name $argv[1]
    set -l id (_zxc_new_id)

    # zmx cannot label a session before it exists, and attach blocks
    # until you detach, so the label is applied from a background job
    # that waits for the session to come up. It has to be this script
    # rather than the function directly: fish runs a backgrounded
    # function synchronously. Output is discarded so it cannot scribble
    # on the session you just attached to.
    $_zxc_script --label "$ZMX_SESSION_PREFIX$id" "$name" >/dev/null 2>&1 &
    disown

    # zmx applies $ZMX_SESSION_PREFIX to the id itself.
    zmx attach $id $argv[2..]
end

function _zxc_set_cwd
    # zmx renders the session through its own VT, so nothing the inner
    # shell emits reaches the terminal: while attached, the terminal
    # still believes the cwd is wherever zxc was run from. Point it at
    # the session's directory so kitty's new_tab_with_cwd opens there.
    #
    # Both halves are needed. The cd fixes what a terminal reads from
    # the foreground process (zmx attach inherits this process's cwd);
    # the OSC 7 fixes what a terminal tracks from the output stream.
    #
    # The tab name is left alone on purpose. A terminal labels the tab
    # from the cwd it was last told about, so it names itself after the
    # session's directory; setting a title here only fought with that.
    set -l dir ""

    for line in (_zxc_sessions)
        set -l parts (string split \t -- $line)

        if test "$parts[1]" = "$argv[1]"
            set dir "$parts[3]"
            break
        end
    end

    test -n "$dir" -a -d "$dir"; or return

    cd $dir

    printf '\e]7;file://%s%s\e\\' $hostname (
        string replace -a ' ' '%20' -- $dir
    )
end

function _zxc_attach
    set -l target (_zxc_resolve "$argv[1]")

    if test -n "$target"
        _zxc_set_cwd "$target"

        ZMX_SESSION_PREFIX= zmx attach "$target" $argv[2..]
        return
    end

    _zxc_create $argv
end

function _zxc_move
    # -1 moves the session up the list, +1 moves it down.
    set -l step $argv[1]
    set -l name $argv[2]

    set -l names
    for line in (_zxc_sessions)
        set -a names (string split -f1 \t -- $line)
    end

    contains -- "$name" $names; or return

    set -l from (contains -i -- "$name" $names)
    set -l to (math $from + $step)

    test $to -ge 1 -a $to -le (count $names); or return

    set names[$from] $names[$to]
    set names[$to] "$name"

    # Give every session an explicit ord, so the order you see is the
    # order that gets recorded and only genuinely new sessions float to
    # the top afterwards. Unpadded on purpose: fish's printf reads a
    # leading zero as octal.
    for i in (seq (count $names))
        ZMX_SESSION_PREFIX= zmx set $names[$i] "ord=$i"
    end
end

function _zxc_preview
    # zmx --vt replays the session's terminal setup sequences, but fzf's
    # preview only understands SGR; anything else leaks as literal text
    # (the kitty-keyboard flags fish emits showed up as "=5;1u"). Strip
    # OSC strings, non-SGR CSI sequences, and charset selections.
    ZMX_SESSION_PREFIX= zmx history "$argv[1]" --vt 2>/dev/null | tail -n 200 |
        string replace -ra '\x1b\][^\a\x1b]*(?:\a|\x1b\x5c)' '' |
        string replace -ra '\x1b\[[0-9;?=<>!]*[@-ln-~]' '' |
        string replace -ra '\x1b[()][A-Za-z0-9]' ''
end

function _zxc_kill
    # Names arrive complete; clear the prefix so zmx does not prepend
    # it a second time.
    while read -l name
        test -n "$name"; or continue

        ZMX_SESSION_PREFIX= zmx kill "$name"
    end
end

function _zxc_rename
    set -l name "$argv[1]"
    test -n "$name"; or return

    # fzf's execute() hands over the terminal, so a plain read works here.
    set -l label (_zxc_display "$name")
    test -n "$label"; or set label "$name"

    read -l -P "rename '$label' (empty = clear) > " new
    or return

    set new (string trim -- "$new")

    # Every row has to stay reachable by the name it shows, so refuse a
    # name some other session already answers to.
    if test -n "$new"
        set -l clash (_zxc_resolve "$new")

        if test -n "$clash" -a "$clash" != "$name"
            echo "zxc: '$new' is already taken by $clash" >&2
            # fzf redraws the moment this returns, so hold the message.
            read -l -P "press enter to continue > " _
            return 1
        end
    end

    ZMX_SESSION_PREFIX= zmx set "$name" "alias=$new"
end

function zxc
    switch "$argv[1]"
        case --candidates
            _zxc_candidates
            return

        case --complete
            _zxc_complete
            return

        case --preview
            _zxc_preview "$argv[2]"
            return

        case --kill
            _zxc_kill
            return

        case --rename
            _zxc_rename "$argv[2]"
            return

        case --label
            _zxc_label_when_ready "$argv[2]" "$argv[3]"
            return

        case --move-up
            _zxc_move -1 "$argv[2]"
            return

        case --move-down
            _zxc_move 1 "$argv[2]"
            return

        case '-*'
            # Without this a typo'd internal flag would quietly become a
            # session name.
            echo "zxc: unknown option: $argv[1]" >&2
            return 2

        case ''
            # No argument: fall through to the picker below. fish removed
            # ? as a glob character, so this cannot be folded into the
            # catch-all pattern.

        case '*'
            _zxc_attach $argv
            return
    end

    set -l self (_zxc_shquote $_zxc_script)

    # Shift+J/K only reorder while the search box is empty, so they stay
    # typeable in a query; shift-up/down work either way. fzf expands
    # {1} before running the transform, so the action it echoes already
    # names the session.
    set -l move_up "execute-silent($self --move-up {1})+reload-sync($self --candidates)"
    set -l move_down "execute-silent($self --move-down {1})+reload-sync($self --candidates)"

    set -l output (
        _zxc_candidates | fzf \
            --delimiter=\t \
            --with-nth=2.. \
            --track \
            --id-nth=1 \
            --print-query \
            --info=inline-right \
            --expect=ctrl-n \
            --height=100% \
            --reverse \
            --pointer="" \
            # --header="enter: select | ctrl-n: new | ctrl-r: rename"\n"shift+J/K or shift-↑/↓: move | ctrl-x: kill" \
            --preview-window=left:60%:follow:border-none \
            --preview="$self --preview {1}" \
            --bind="every(1):refresh-preview" \
            --bind="ctrl-r:execute($self --rename {1})+reload($self --candidates)" \
            --bind="shift-up:$move_up" \
            --bind="shift-down:$move_down" \
            --bind="K:transform:test -z \"\$FZF_QUERY\" && echo \"$move_up\" || echo \"put(K)\"" \
            --bind="J:transform:test -z \"\$FZF_QUERY\" && echo \"$move_down\" || echo \"put(J)\"" \
            --bind="ctrl-x:execute-silent(printf '%s\n' {1} | $self --kill)+reload($self --candidates)"
    )

    set -l rc $status

    # fzf exits 1 when nothing matched, which is exactly when the query
    # should become a new session. Only 2 (error) and 130 (interrupted)
    # mean give up.
    if test $rc -ge 2
        return $rc
    end

    set -l query ""
    set -l key ""
    set -l selected ""

    if test (count $output) -ge 1
        set query "$output[1]"
    end

    if test (count $output) -ge 2
        set key "$output[2]"
    end

    if test (count $output) -ge 3
        set selected "$output[3]"
    end

    # ctrl-n creates a session named after the query even when a row is
    # highlighted; otherwise the highlighted row wins.
    set -l force_new (test "$key" = ctrl-n -a -n "$query"; and echo 1)

    if test -n "$selected" -a -z "$force_new"
        # Field 1 is already the complete name.
        set -l name (string split -f1 \t -- "$selected")

        _zxc_set_cwd "$name"

        ZMX_SESSION_PREFIX= zmx attach "$name"
        return
    end

    if test -z "$query"
        return 130
    end

    _zxc_create "$query"
end

zxc $argv
