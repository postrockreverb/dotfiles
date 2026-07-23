#!/bin/bash

set -euo pipefail

log() {
    printf "\n[%s] %s\n" "$(date '+%H:%M:%S')" "$*"
}

remove_dir() {
    local dir="$1"

    if [[ -d "$dir" ]]; then
        local size
        size=$(du -sh "$dir" 2>/dev/null | cut -f1)

        log "Removing $dir ($size)"
        rm -rf "$dir"
    else
        log "Skipping $dir (not found)"
    fi
}

log "Starting cache cleanup"

remove_dir "$HOME/.bun/install/cache"
remove_dir "$HOME/.yarn/berry/cache"
remove_dir "$HOME/.npm/_cacache"

remove_dir "$HOME/.cache/uv"
remove_dir "$HOME/.cache/yarn"
remove_dir "$HOME/.cache/pip"
remove_dir "$HOME/.cache/pnpm"

remove_dir "$HOME/.cargo/registry/cache"
remove_dir "$HOME/.cargo/git/db"

log "Cleaning Cargo cache"
cargo cache --autoclean || true

log "Pruning pnpm store"
pnpm store prune || true

log "Cleaning npm cache"
npm cache clean --force || true

log "Cleaning Bun cache"
bun pm cache rm || true

log "Cleaning Homebrew cache"
brew cleanup --prune=all

log "Removing unused Homebrew dependencies"
brew autoremove

log "Cleaning pip cache"
python3 -m pip cache purge || true

log "Cleaning Go module cache"
go clean --modcache

log "Pruning Docker resources"
docker system df || true

docker system prune -a --volumes --force

log "Removing Docker build history"
docker buildx history rm --all || true

log "Docker disk usage after cleanup"
docker system df || true

log "Cleanup completed"
