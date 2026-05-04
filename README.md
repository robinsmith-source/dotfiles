# dotfiles

Personal dotfiles for CachyOS + [Niri](https://github.com/YaLTeR/niri) + [Noctalia](https://docs.noctalia.dev).

## Stack

| Layer | Tool |
|---|---|
| OS | CachyOS (Arch-based) |
| Compositor | Niri (Wayland) |
| Desktop shell | Noctalia (via Quickshell) |
| Terminal | Alacritty |
| Shell | Fish |
| Editor | Neovim (LazyVim) · Zed · VS Code |
| Theme | Noctalia |

## Fresh install

### 1. Prerequisites

Install an AUR helper if not already present:

```bash
sudo pacman -S --needed base-devel git
git clone https://aur.archlinux.org/paru.git && cd paru && makepkg -si
```

### 2. Clone the dotfiles

```bash
git clone --bare git@github.com:robinsmith-source/dotfiles.git "$HOME/.dotfiles"
alias dots='git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME"'
dots checkout
dots config status.showUntrackedFiles no
```

If checkout fails due to conflicting files, back them up first:

```bash
dots checkout 2>&1 | grep '^\s' | awk '{print $1}' | xargs -I{} mv {} {}.bak
dots checkout
```

### 3. Install packages

```bash
bash ~/install.sh
```

Or skip cloning entirely and run it directly:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/robinsmith-source/dotfiles/main/install.sh)
```

This installs all packages, enables services, sets your Git identity, and sets fish as the default shell.

### 4. Post-install

- Log out and back in for the docker group and shell change to take effect.
- See [docs.noctalia.dev](https://docs.noctalia.dev) to finish the Noctalia shell setup.

## Updating

```bash
bash ~/update.sh
```

Pulls the latest dotfiles, updates system packages (pacman + AUR), and upgrades mise runtimes.

## Managing dotfiles

The `dots` alias is a git command scoped to the bare repo:

```bash
dots status
dots add ~/.config/alacritty/alacritty.toml
dots commit -m "feat: update alacritty config"
dots push
```
