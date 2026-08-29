#!/usr/bin/env fish

# zxc - fzf picker for zmx sessions.
#
# Doubles as its own helper: fzf runs binds and the preview through sh,
# which cannot see fish functions, so they re-invoke this script.

set -g _zxc_script (path resolve (status filename))

function _zxc_shquote
    # sh-safe single quoting; stands in for bash's printf %q, which
    # fish's printf does not implement.
    printf "'%s'" (string replace -a -- "'" "'\\''" "$argv[1]")
end

function _zxc_candidates
    set -l prefix "$ZMX_SESSION_PREFIX"

    zmx list 2>/dev/null | while read -d \t name dir
        set name (string replace -r '^.*name=' '' -- "$name")
        set dir (string replace -r '^.*start_dir=' '' -- "$dir")
        # Session labels arrive as extra tab-separated fields after
        # start_dir; drop them so they do not corrupt the path.
        set dir (string split -f1 \t -- "$dir")

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

        # Field 1 is the complete session name, hidden from view by
        # --with-nth, so {1} always names something zmx can resolve.
        printf '%s\t%-20s  %s\n' "$name" "$display" "$dir"
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

function zxc
    switch "$argv[1]"
        case --candidates
            _zxc_candidates
            return

        case --preview
            _zxc_preview "$argv[2]"
            return

        case --kill
            _zxc_kill
            return
    end

    set -l self (_zxc_shquote $_zxc_script)

    set -l output (
        _zxc_candidates | fzf \
            --delimiter=\t \
            --with-nth=2.. \
            --print-query \
            --info=inline-right \
            --expect=ctrl-n \
            --height=100% \
            --reverse \
            --pointer="" \
            --header="<enter> select | <ctrl-n>: create new | <ctrl-x>: kill" \
            --preview-window=left:60%:follow:border-none \
            --preview="$self --preview {1}" \
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
        ZMX_SESSION_PREFIX= zmx attach (string split -f1 \t -- "$selected")
        return
    end

    if test -z "$query"
        return 130
    end

    # New session: zmx applies $ZMX_SESSION_PREFIX itself.
    zmx attach "$query"
end

zxc $argv
