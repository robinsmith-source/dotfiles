#!/usr/bin/env bash
# Bootstrap packages for this dotfiles setup on CachyOS / Arch Linux.
#
# Usage:
#   locally:  bash install.sh
#   via curl: bash <(curl -fsSL https://raw.githubusercontent.com/robinsmith-source/dotfiles/main/install.sh)
#
# Note: use bash <(curl ...) not curl ... | bash — the latter breaks interactive prompts.

set -euo pipefail

info()    { printf '\033[0;34m==> %s\033[0m\n' "$*"; }
success() { printf '\033[0;32m  ✓ %s\033[0m\n' "$*"; }
warn()    { printf '\033[0;33m  ! %s\033[0m\n' "$*"; }
die()     { printf '\033[0;31m[error] %s\033[0m\n' "$*" >&2; exit 1; }

# ── AUR helper ────────────────────────────────────────────────────────────────

if command -v paru &>/dev/null; then
    AUR=paru
elif command -v yay &>/dev/null; then
    AUR=yay
else
    die "No AUR helper found. Install paru or yay first:\n  sudo pacman -S --needed base-devel git\n  git clone https://aur.archlinux.org/paru.git && cd paru && makepkg -si"
fi

# ── Official repo packages ─────────────────────────────────────────────────────

PACMAN_PKGS=(
    # build essentials
    base-devel
    git
    openssh
    curl
    wget
    less

    # wayland / compositor
    niri
    xdg-desktop-portal
    xdg-desktop-portal-gnome

    # terminal & shell
    alacritty
    fish
    kitty-terminfo          # SSH compatibility when using kitty/alacritty

    # editors
    neovim
    luarocks                # neovim plugin dependencies
    zed

    # GUI apps
    nautilus
    gnome-keyring

    # system monitoring
    btop
    fastfetch

    # dev tools
    lazygit
    github-cli
    docker
    docker-buildx
    docker-compose

    # CLI essentials (adapted from omaterm)
    fzf
    eza
    zoxide
    bat
    ripgrep
    fd
    jq
    gum
    man-db
    tldr

    # fonts
    ttf-jetbrains-mono-nerd
    noto-fonts
    noto-fonts-emoji

    # misc system
    xdg-utils
    polkit-kde-authentication-agent
)

# ── AUR packages ──────────────────────────────────────────────────────────────

AUR_PKGS=(
    zen-browser-bin             # browser (Mod+B in niri keybinds)
    visual-studio-code-bin      # VS Code (Mod+V in niri keybinds)
    lazydocker                  # docker TUI
    bun-bin                     # JavaScript runtime / package manager
    claude-code                 # Anthropic Claude CLI
    opencode-bin                # AI coding assistant
    quickshell-git              # Quickshell (qs) — runtime for noctalia-shell
)

# ── Evaluate ──────────────────────────────────────────────────────────────────

info "Evaluating installed packages..."

PACMAN_MISSING=()
PACMAN_PRESENT=()
for pkg in "${PACMAN_PKGS[@]}"; do
    if pacman -Q "$pkg" &>/dev/null; then
        PACMAN_PRESENT+=("$pkg")
    else
        PACMAN_MISSING+=("$pkg")
    fi
done

AUR_MISSING=()
AUR_PRESENT=()
for pkg in "${AUR_PKGS[@]}"; do
    if pacman -Q "$pkg" &>/dev/null; then
        AUR_PRESENT+=("$pkg")
    else
        AUR_MISSING+=("$pkg")
    fi
done

total_present=$(( ${#PACMAN_PRESENT[@]} + ${#AUR_PRESENT[@]} ))
total_missing=$(( ${#PACMAN_MISSING[@]} + ${#AUR_MISSING[@]} ))

printf '\n  \033[0;32m%d already installed\033[0m' "$total_present"
for pkg in "${PACMAN_PRESENT[@]}" "${AUR_PRESENT[@]}"; do
    printf '\n    · %s' "$pkg"
done

printf '\n\n  \033[0;34m%d to install\033[0m' "$total_missing"
for pkg in "${PACMAN_MISSING[@]}" "${AUR_MISSING[@]}"; do
    printf '\n    · %s' "$pkg"
done
printf '\n\n'

if [[ $total_missing -eq 0 ]]; then
    success "All packages already installed."
else
    # ── Install ─────────────────────────────────────────────────────────────────

    info "Updating package database..."
    sudo pacman -Sy

    if [[ ${#PACMAN_MISSING[@]} -gt 0 ]]; then
        info "Installing ${#PACMAN_MISSING[@]} official packages..."
        sudo pacman -S --needed --noconfirm "${PACMAN_MISSING[@]}"
        success "Official packages installed."
    fi

    if [[ ${#AUR_MISSING[@]} -gt 0 ]]; then
        info "Installing ${#AUR_MISSING[@]} AUR packages via $AUR..."
        $AUR -S --needed --noconfirm "${AUR_MISSING[@]}"
        success "AUR packages installed."
    fi
fi

# ── Locale & timezone ─────────────────────────────────────────────────────────

info "Setting up locale and timezone..."

current_tz=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "UTC")
read -rp "  Timezone [$current_tz]: " tz
tz="${tz:-$current_tz}"
sudo timedatectl set-timezone "$tz"
sudo timedatectl set-ntp true

current_locale=$(locale | grep '^LANG=' | cut -d= -f2 || echo "")
read -rp "  Locale [${current_locale:-en_US.UTF-8}]: " locale
locale="${locale:-${current_locale:-en_US.UTF-8}}"

if ! grep -q "^${locale}" /etc/locale.gen; then
    sudo sed -i "s|^#${locale}|${locale}|" /etc/locale.gen
    sudo locale-gen
fi
sudo localectl set-locale "LANG=${locale}"
success "Locale set to $locale, timezone set to $tz."

# ── Git identity ──────────────────────────────────────────────────────────────

info "Setting up Git identity..."

current_name=$(git config --global user.name 2>/dev/null || true)
current_email=$(git config --global user.email 2>/dev/null || true)

if [[ -n "$current_name" ]]; then
    read -rp "  Git user name [$current_name]: " git_name
    git_name="${git_name:-$current_name}"
else
    read -rp "  Git user name: " git_name
fi

if [[ -n "$current_email" ]]; then
    read -rp "  Git email address [$current_email]: " git_email
    git_email="${git_email:-$current_email}"
else
    read -rp "  Git email address: " git_email
fi

git config --global user.name  "$git_name"
git config --global user.email "$git_email"
success "Git identity set: $git_name <$git_email>"

# ── Services ──────────────────────────────────────────────────────────────────

info "Enabling system services..."
sudo systemctl enable --now docker.service
sudo systemctl enable --now sshd.service
success "Services enabled."

info "Adding $USER to docker group (takes effect on next login)..."
sudo usermod -aG docker "$USER"

# ── Shell ─────────────────────────────────────────────────────────────────────

if [[ "$SHELL" != "$(command -v fish)" ]]; then
    info "Setting fish as default shell..."
    chsh -s "$(command -v fish)"
    success "Default shell changed to fish. Log out to apply."
fi

# ── Done ──────────────────────────────────────────────────────────────────────

echo
success "All done! Log out and back in for group and shell changes to take effect."
warn "Noctalia shell config lives in ~/.config/noctalia/ — see https://docs.noctalia.dev for setup."
