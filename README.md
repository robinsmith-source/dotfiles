# dotfiles

CachyOS + [Niri](https://github.com/YaLTeR/niri) + [Noctalia](https://docs.noctalia.dev), managed with [chezmoi](https://www.chezmoi.io).

![desktop](https://raw.githubusercontent.com/robinsmith-source/dotfiles/screenshots/screenshot.png)

## What's inside

| Config | Notes |
| --- | --- |
| [niri](home/dot_config/niri) | Split into `cfg/*.kdl`; outputs and input are templated per machine |
| [noctalia](home/dot_config/noctalia) | Bar, widgets, wallpaper; generates the Neovim colorscheme via matugen |
| [nvim](home/dot_config/nvim) | LazyVim + base16, themed from the current wallpaper |
| [fish](home/dot_config/fish) | On top of the CachyOS fish config |
| [alacritty](home/dot_config/alacritty), [zed](home/dot_config/zed), [btop](home/dot_config/btop), [fastfetch](home/dot_config/fastfetch) | |
| [git](home/dot_gitconfig.tmpl) | SSH-signed commits via the Bitwarden SSH agent |

Press `Mod+Shift+Esc` in niri for the full keybind overlay.

## Install

```bash
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- init --apply git@github.com:robinsmith-source/dotfiles.git
```

chezmoi prompts for your git name/email once. Then it:

1. installs the Bitwarden CLI (`bw`) if missing, so templates can read secrets
2. offers to install missing packages from [`packages.yaml`](home/.chezmoidata/packages.yaml)
   (first run, and again whenever that file changes)
3. installs the pre-commit hooks for this repo
4. validates the niri and noctalia configs after every apply

## Machines

Differences are handled in `.tmpl` files via chezmoi data:

- **`.laptop`**: true when the hostname is `goblin`. Switches monitor layout, keyboard layout
  (`de,us`), focus behaviour and adds laptop-only packages (`upower`, `power-profiles-daemon`).
- **CachyOS**: `pacman_cachyos` packages are only installed when `/etc/os-release` says `cachyos`.

## Daily use

```bash
chezmoi edit ~/.config/niri/cfg/keybinds.kdl   # edit the source, not the target
chezmoi diff                                   # preview
chezmoi apply                                  # deploy
chezmoi add ~/.config/foo/bar.conf             # start tracking a file
chezmoi update                                 # pull + apply + install new packages
sudo pacman -Syu                               # upgrade installed packages
```

To add a package, put it in the right list in `packages.yaml`. Use `pacman`, `pacman_laptop`,
`pacman_cachyos` or `aur`.

## Screenshot

The image above lives on the `screenshots` branch. To refresh it, push with `SCREENSHOT=1 git push`
or run `scripts/screenshot.sh`. It opens a demo workspace (nvim, fastfetch, btop) on `DP-1`,
screenshots it, closes everything and force-pushes the image. Use `--local` to only save it.

## Secrets

This repo is public. Never commit secrets; pull them from Bitwarden in `.tmpl` files instead:

```
{{ (bitwarden "item" "Item Name").login.password }}
```

## Checks

- **pre-commit** (local + CI): gitleaks, shellcheck, shfmt, stylua, YAML/TOML/JSON sanity
- **CI** also runs gitleaks + trufflehog over the full history, luacheck, and a clean
  `chezmoi apply` in an Arch container that validates niri, noctalia, fish, the rendered
  install script and all package names
- **Renovate** bumps pre-commit hooks and GitHub Actions weekly
