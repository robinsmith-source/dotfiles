# dotfiles

Personal dotfiles for CachyOS + [Niri](https://github.com/YaLTeR/niri) + [Noctalia](https://docs.noctalia.dev), managed with [chezmoi](https://www.chezmoi.io).

## Install

```bash
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- init --apply git@github.com:robinsmith-source/dotfiles.git
```

Or, if chezmoi is already installed:

```bash
chezmoi init --apply git@github.com:robinsmith-source/dotfiles.git
```

`chezmoi apply` installs packages, runs one-time machine setup, and validates configs on its own.
See the `run_*` scripts under `home/` for details.

## Update

```bash
chezmoi update
```

Pulls the latest dotfiles, re-applies, and installs any newly-added packages. Does not upgrade
already-installed packages. Run `sudo pacman -Syu` for that.

## Secrets

Never hardcode real secrets into tracked files — this repo is public. `.tmpl` files can pull
values from Bitwarden instead:

```
{{ (bitwarden "item" "Item Name").login.password }}
```

CI runs [gitleaks](https://github.com/gitleaks/gitleaks) on every push/PR as a backstop.
