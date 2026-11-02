#!/usr/bin/env fish

# Link instructions; configuration and state stay local in ~/.codex.
set -l source_dir (path dirname (path resolve (status filename)))
set -l codex_dir "$HOME/.codex"
set -g codex_backup_dir

if test (count $argv) -ne 0
    echo "Usage: fish $source_dir/install.fish" >&2
    exit 1
end

if set -q CODEX_HOME; and test -n "$CODEX_HOME"
    if test (path resolve "$CODEX_HOME") != (path resolve "$codex_dir")
        echo "CODEX_HOME points elsewhere: $CODEX_HOME. This installer uses $codex_dir." >&2
        exit 1
    end
end

function backup_codex_path --argument-names target backup_path
    if test -z "$codex_backup_dir"
        mkdir -p "$HOME/.codex/backups"; or return 1
        set -g codex_backup_dir (mktemp -d "$HOME/.codex/backups/dotfiles-"(date +%Y%m%d-%H%M%S)".XXXXXX"); or return 1
    end

    set -l backup "$codex_backup_dir/$backup_path"
    mkdir -p (path dirname "$backup"); or return 1
    mv "$target" "$backup"; or return 1
    echo "Backed up: $target -> $backup"
end

function install_codex_link --argument-names source target backup_path
    if not test -e "$source"
        echo "Missing configuration: $source" >&2
        return 1
    end

    if test -e "$target"; or test -L "$target"
        set -l resolved_target (path resolve "$target" 2>/dev/null)
        if test "$resolved_target" = "$source"
            echo "Already linked: $target"
            return 0
        end
        backup_codex_path "$target" "$backup_path"; or return 1
    end

    mkdir -p (path dirname "$target"); or return 1
    ln -s "$source" "$target"; or return 1
    echo "Linked: $target -> $source"
end

install_codex_link "$source_dir/AGENTS.md" "$codex_dir/AGENTS.md" codex/AGENTS.md; or exit 1
install_codex_link "$source_dir/skills/handoff" "$HOME/.agents/skills/handoff" agents/skills/handoff; or exit 1

if test -n "$codex_backup_dir"
    echo "Original files are in $codex_backup_dir"
end
