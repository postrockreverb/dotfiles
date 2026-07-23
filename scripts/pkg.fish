#!/usr/bin/env fish

function usage
    echo "Usage:"
    echo "  pkg.fish list <manager>"
    echo "  pkg.fish remove <manager> <package...>"
    exit 1
end

function go_bindir
    set bindir (go env GOBIN)

    if test -z "$bindir"
        echo (go env GOPATH)/bin
    else
        echo $bindir
    end
end

function list_packages
    set manager $argv[1]

    switch $manager
        case brew
            brew list --formula

        case brew-cask
            brew list --cask

        case npm
            npm list -g --depth=0

        case pnpm
            pnpm list -g --depth=-1

        case bun
            bun pm --g

        case cargo
            cargo install --list \
                | string match -r '^[^ ]+ v' \
                | string replace -r ' v.*' ''

        case pip
            python3 -m pip list

        case uv
            uv tool list

        case go
            ls (go_bindir)

        case '*'
            echo "Unknown package manager: $manager"
            exit 1
    end
end

function remove_packages
    set manager $argv[1]
    set packages $argv[2..-1]

    switch $manager
        case brew
            brew uninstall $packages

        case brew-cask
            brew uninstall --cask $packages

        case npm
            npm uninstall -g $packages

        case pnpm
            pnpm remove -g $packages

        case bun
            bun remove -g $packages

        case cargo
            for pkg in $packages
                cargo uninstall $pkg
            end

        case pip
            python3 -m pip uninstall --break-system-packages -y $packages

        case uv
            uv tool uninstall $packages

        case go
            set bindir (go_bindir)

            for pkg in $packages
                rm -f "$bindir/$pkg"
            end

        case '*'
            echo "Unknown package manager: $manager"
            exit 1
    end
end

if test (count $argv) -lt 2
    usage
end

set command $argv[1]

switch $command
    case list
        if test (count $argv) -ne 2
            usage
        end

        list_packages $argv[2]

    case remove
        if test (count $argv) -lt 3
            usage
        end

        remove_packages $argv[2..-1]

    case '*'
        usage
end
