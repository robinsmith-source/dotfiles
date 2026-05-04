#!/usr/bin/env bash
# Pull latest dotfiles, update system packages and runtimes.
# Usage: bash update.sh

set -euo pipefail

info()    { printf '\033[0;34m==> %s\033[0m\n' "$*"; }
success() { printf '\033[0;32m  ✓ %s\033[0m\n' "$*"; }

DOTS="git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME"

info "Pulling dotfiles..."
$DOTS fetch origin
$DOTS merge origin/"$(git --git-dir="$HOME/.dotfiles/" symbolic-ref --short HEAD)"
success "Dotfiles up to date."

info "Updating system packages..."
sudo pacman -Syu --noconfirm
success "System packages updated."

if command -v paru &>/dev/null; then
    info "Updating AUR packages..."
    paru -Sua --noconfirm
    success "AUR packages updated."
elif command -v yay &>/dev/null; then
    info "Updating AUR packages..."
    yay -Sua --noconfirm
    success "AUR packages updated."
fi

echo
success "All done."
