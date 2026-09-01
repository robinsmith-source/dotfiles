#!/usr/bin/env bash
# Bootstrap packages for this dotfiles setup on CachyOS / Arch Linux.
#
# Targets the CachyOS niri + noctalia stack:
#   cachyos-niri-noctalia  meta package (niri, noctalia, portals, cursors, fonts)
#   noctalia 5.x           standalone shell binary — no quickshell/`qs` needed
#   noctalia-greeter       optional greetd greeter
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

ask_yn() {  # ask_yn <prompt> <default y|n> — returns 0 for yes
    local prompt=$1 default=$2 reply hint
    [[ $default == y ]] && hint="[Y/n]" || hint="[y/N]"
    read -rp "  $prompt $hint: " reply
    reply="${reply:-$default}"
    [[ ${reply,,} == y* ]]
}

# ── Sanity checks ─────────────────────────────────────────────────────────────

command -v pacman &>/dev/null || die "This script targets Arch-based systems (pacman not found)."

# The niri/noctalia packages live in the CachyOS repos. On plain Arch, `noctalia`
# is in [extra] but cachyos-niri-noctalia / noctalia-greeter / zen-browser-bin are not.
if pacman -Si cachyos-niri-noctalia &>/dev/null; then
    ON_CACHYOS=1
else
    ON_CACHYOS=0
    warn "CachyOS repos not detected — CachyOS-only packages will be skipped."
fi

# ── AUR helper (optional) ─────────────────────────────────────────────────────
# Nearly everything moved into the CachyOS repos; only VS Code still needs the AUR.

if command -v paru &>/dev/null; then
    AUR=paru
elif command -v yay &>/dev/null; then
    AUR=yay
else
    AUR=""
    warn "No AUR helper found — AUR packages will be skipped."
    warn "To install one:  sudo pacman -S --needed base-devel git"
    warn "                 git clone https://aur.archlinux.org/paru.git && cd paru && makepkg -si"
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
    chezmoi

    # ─── desktop: niri + noctalia ───
    # cachyos-niri-noctalia pulls in niri, noctalia, capitaine-cursors, wl-clipboard,
    # xwayland-satellite, adw-gtk-theme and the portals. Listed individually below too,
    # so the summary reports honestly and plain-Arch installs still work.
    niri
    noctalia                # noctalia 5.x — provides the `noctalia` binary directly
    xwayland-satellite      # X11 apps under niri
    xdg-desktop-portal
    xdg-desktop-portal-gnome
    xdg-desktop-portal-gtk
    capitaine-cursors       # cursor theme referenced in niri/cfg/misc.kdl
    wl-clipboard            # wl-copy / wl-paste — clipboard history + screenshots
    cliphist                # clipboard history store (noctalia appLauncher)
    adw-gtk-theme

    # noctalia widget / plugin dependencies
    cava                    # audio visualizer widget
    ddcutil                 # external monitor brightness (brightness.enableDdcSupport)
    brightnessctl           # internal backlight control
    upower                  # battery widget
    power-profiles-daemon   # PowerProfile shortcut + battery widget
    networkmanager          # Network / VPN widgets
    bluez                   # Bluetooth widget
    bluez-utils
    pavucontrol             # Volume widget middle-click fallback
    pwvucontrol             # preferred PipeWire mixer
    gpu-screen-recorder     # screen-recorder plugin
    wl-mirror               # mirror-mirror plugin + Mod+Ctrl+E keybind
    tailscale               # tailscale plugin
    polkit                  # noctalia's built-in polkit-agent plugin

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
    gnome-keyring           # spawned by niri/cfg/autostart.kdl
    zen-browser-bin         # browser (Mod+B in niri keybinds) — now in the cachyos repo

    # system monitoring
    btop                    # Mod+P, and noctalia's externalMonitor command
    fastfetch

    # dev tools
    lazygit
    github-cli
    docker
    docker-buildx
    docker-compose
    lazydocker
    bun                     # JavaScript runtime / package manager
    claude-code             # Anthropic Claude CLI
    opencode                # AI coding assistant

    # CLI essentials
    fzf
    eza
    zoxide
    bat
    ripgrep
    fd
    jq                      # used by the Mod+Ctrl+E mirror keybind
    gum
    man-db
    tldr

    # fonts
    ttf-jetbrains-mono-nerd # "JetBrainsMono NF" — noctalia ui.fontDefault
    noto-fonts
    noto-fonts-emoji

    # misc system
    xdg-utils
)

# CachyOS-only extras
if [[ $ON_CACHYOS -eq 1 ]]; then
    PACMAN_PKGS+=(
        cachyos-niri-noctalia   # niri + noctalia settings meta package
        cachyos-alacritty-config
    )
else
    # zen-browser-bin and claude-code are CachyOS-repo packages; fall back to the AUR.
    PACMAN_PKGS=("${PACMAN_PKGS[@]/zen-browser-bin/}")
    PACMAN_PKGS=("${PACMAN_PKGS[@]/claude-code/}")
fi

# ── AUR packages ──────────────────────────────────────────────────────────────

AUR_PKGS=(
    visual-studio-code-bin  # VS Code (Mod+V in niri keybinds) — Marketplace build
)

if [[ $ON_CACHYOS -eq 0 ]]; then
    AUR_PKGS+=(zen-browser-bin claude-code)
fi

# ── Evaluate ──────────────────────────────────────────────────────────────────

info "Evaluating installed packages..."

PACMAN_MISSING=()
PACMAN_PRESENT=()
for pkg in "${PACMAN_PKGS[@]}"; do
    [[ -z $pkg ]] && continue
    if pacman -Q "$pkg" &>/dev/null; then
        PACMAN_PRESENT+=("$pkg")
    elif ! pacman -Si "$pkg" &>/dev/null; then
        warn "$pkg not available in any enabled repo — skipping."
    else
        PACMAN_MISSING+=("$pkg")
    fi
done

AUR_MISSING=()
AUR_PRESENT=()
for pkg in "${AUR_PKGS[@]}"; do
    if pacman -Q "$pkg" &>/dev/null; then
        AUR_PRESENT+=("$pkg")
    elif [[ -n $AUR ]]; then
        AUR_MISSING+=("$pkg")
    else
        warn "$pkg needs an AUR helper — skipping."
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
    # ── Conflict check ──────────────────────────────────────────────────────────
    # cachyos-niri-noctalia conflicts with cachyos-desktop-settings, which ships on
    # stock CachyOS installs. --noconfirm aborts on conflicts, so resolve it up front.
    if printf '%s\n' "${PACMAN_MISSING[@]}" | grep -qx cachyos-niri-noctalia \
       && pacman -Q cachyos-desktop-settings &>/dev/null; then
        warn "cachyos-niri-noctalia conflicts with the installed cachyos-desktop-settings."
        if ask_yn "Remove cachyos-desktop-settings and continue?" n; then
            sudo pacman -Rdd --noconfirm cachyos-desktop-settings
            success "cachyos-desktop-settings removed."
        else
            die "Aborted. Remove cachyos-desktop-settings manually, or drop cachyos-niri-noctalia from PACMAN_PKGS."
        fi
    fi

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
for svc in docker.service sshd.service bluetooth.service NetworkManager.service \
           power-profiles-daemon.service tailscaled.service; do
    if systemctl list-unit-files "$svc" &>/dev/null && [[ -n $(systemctl list-unit-files "$svc" 2>/dev/null | sed -n 2p) ]]; then
        sudo systemctl enable --now "$svc" 2>/dev/null && success "$svc enabled." \
            || warn "Could not enable $svc."
    fi
done

# Note: `pacman -Q docker` matches provides, so podman-docker satisfies it and the
# real docker package/service may be absent. Only touch the group if it exists.
if getent group docker &>/dev/null; then
    info "Adding $USER to docker group (takes effect on next login)..."
    sudo usermod -aG docker "$USER"
else
    warn "No docker group present — skipping group membership."
fi

# ── Greeter (opt-in) ──────────────────────────────────────────────────────────
# noctalia-greeter is a greetd greeter. Enabling it swaps your login path, so it
# stays opt-in — if it misbehaves you are left at a TTY.

if [[ $ON_CACHYOS -eq 1 ]]; then
    if ! pacman -Q noctalia-greeter &>/dev/null; then
        if ask_yn "Install noctalia-greeter (greetd login screen)?" n; then
            sudo pacman -S --needed --noconfirm noctalia-greeter
            success "noctalia-greeter installed."
        fi
    fi

    if pacman -Q noctalia-greeter &>/dev/null && [[ $(systemctl is-enabled greetd 2>/dev/null) != enabled ]]; then
        warn "greetd is installed but not enabled — niri currently starts from a TTY."
        if ask_yn "Enable greetd as the display manager?" n; then
            sudo systemctl enable greetd.service
            success "greetd enabled (takes effect on next boot)."
            warn "Verify /etc/greetd/config.toml launches noctalia-greeter before rebooting."
        fi
    fi
fi

# ── Shell ─────────────────────────────────────────────────────────────────────

if [[ "$SHELL" != "$(command -v fish)" ]]; then
    info "Setting fish as default shell..."
    chsh -s "$(command -v fish)"
    success "Default shell changed to fish. Log out to apply."
fi

# ── Wallpapers ────────────────────────────────────────────────────────────────
# noctalia's wallpaper.directory points here; it warns on every start if missing.

if [[ ! -d "$HOME/Pictures/Wallpapers" ]]; then
    info "Creating wallpaper directory..."
    mkdir -p "$HOME/Pictures/Wallpapers"
    success "Created ~/Pictures/Wallpapers — drop wallpapers in before launching niri."
fi

# ── Validate configs ──────────────────────────────────────────────────────────

info "Validating configs..."
if command -v niri &>/dev/null && [[ -f "$HOME/.config/niri/config.kdl" ]]; then
    niri validate && success "niri config is valid." || warn "niri config has errors (see above)."
fi
if command -v noctalia &>/dev/null; then
    noctalia config validate || warn "noctalia config has errors (see above)."
fi

# ── Done ──────────────────────────────────────────────────────────────────────

echo
success "All done! Log out and back in for group and shell changes to take effect."
warn "Start niri from a TTY with 'niri-session', or pick it at your greeter."
warn "Noctalia 5.x: config lives in ~/.config/noctalia/config.toml,"
warn "  live settings in ~/.local/state/noctalia/settings.toml — see https://docs.noctalia.dev"
warn "Run 'sudo tailscale up' to finish Tailscale setup (the noctalia plugin needs it)."
