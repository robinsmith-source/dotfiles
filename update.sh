#!/usr/bin/env bash
# Pull latest dotfiles, update system packages, and re-validate the niri/noctalia configs.
# Usage: bash update.sh

set -euo pipefail

info()    { printf '\033[0;34m==> %s\033[0m\n' "$*"; }
success() { printf '\033[0;32m  ✓ %s\033[0m\n' "$*"; }
warn()    { printf '\033[0;33m  ! %s\033[0m\n' "$*"; }

DOTS="git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME"

pkgver() { pacman -Q "$1" 2>/dev/null | awk '{print $2}'; }

# Record versions of the desktop stack so we can tell the user what needs a restart.
before_niri=$(pkgver niri)
before_noctalia=$(pkgver noctalia)

# ── Dotfiles ──────────────────────────────────────────────────────────────────

info "Pulling dotfiles..."
$DOTS fetch origin
$DOTS merge origin/"$(git --git-dir="$HOME/.dotfiles/" symbolic-ref --short HEAD)"
success "Dotfiles up to date."

# ── Packages ──────────────────────────────────────────────────────────────────

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

# ── Pacnew files ──────────────────────────────────────────────────────────────
# cachyos-niri-noctalia ships defaults under /etc/skel and /etc/dconf; upstream
# changes land as .pacnew rather than overwriting, so surface them.

pacnew=$(find /etc -name '*.pacnew' 2>/dev/null || true)
if [[ -n $pacnew ]]; then
    warn "$(wc -l <<<"$pacnew") .pacnew file(s) to merge:"
    while IFS= read -r f; do printf '    · %s\n' "$f"; done <<<"$pacnew"
fi

# ── Config validation ─────────────────────────────────────────────────────────
# A niri or noctalia upgrade can retire config keys. Catch it here rather than at
# next login, when a broken config drops you to a black screen.

info "Validating configs..."

if command -v niri &>/dev/null && [[ -f "$HOME/.config/niri/config.kdl" ]]; then
    if niri validate; then
        success "niri config is valid."
    else
        warn "niri config has errors — fix before logging out."
    fi
fi

if command -v noctalia &>/dev/null; then
    noctalia config validate || warn "noctalia config has errors — fix before logging out."
fi

# noctalia 5.x moved from settings.json to TOML. A leftover settings.json is inert
# and quietly out of date, which is worse than absent.
if [[ -f "$HOME/.config/noctalia/settings.json" ]]; then
    warn "~/.config/noctalia/settings.json is a noctalia 4.x file and is no longer read."
    warn "  Live settings now live in ~/.local/state/noctalia/settings.toml"
    warn "  Export the current state with: noctalia config export merged"
fi

# quickshell is gone in noctalia 5.x — 'qs -c noctalia-shell ...' commands now fail.
# Scan only files we own; the bundled plugin sources under plugins/ are upstream code.
if ! command -v qs &>/dev/null; then
    own_cfg=(
        "$HOME/.config/noctalia/config.toml"
        "$HOME/.config/noctalia/settings.json"
        "$HOME/.config/noctalia/user-templates.toml"
        "$HOME/.local/state/noctalia/settings.toml"
    )
    stale=$(grep -sl 'qs -c noctalia-shell' "${own_cfg[@]}" 2>/dev/null || true)
    if [[ -n $stale ]]; then
        warn "Stale 'qs -c noctalia-shell' commands found (quickshell is not installed):"
        while IFS= read -r f; do printf '    · %s\n' "$f"; done <<<"$stale"
        warn "  Replace with the noctalia CLI, e.g. 'noctalia msg dpms-off' / 'noctalia msg dpms-on'."
    fi
fi

# ── Restart hints ─────────────────────────────────────────────────────────────

after_niri=$(pkgver niri)
after_noctalia=$(pkgver noctalia)

if [[ "$before_noctalia" != "$after_noctalia" ]]; then
    warn "noctalia updated: ${before_noctalia:-none} → ${after_noctalia:-none}"
    if command -v noctalia &>/dev/null && noctalia msg config-reload &>/dev/null; then
        success "Reloaded the running noctalia instance."
    else
        warn "  Restart the shell to pick it up: pkill noctalia && noctalia -d"
    fi
fi

if [[ "$before_niri" != "$after_niri" ]]; then
    warn "niri updated: ${before_niri:-none} → ${after_niri:-none} — log out and back in to apply."
fi

echo
success "All done."
