# dotfiles

Personal dotfiles for CachyOS + [Niri](https://github.com/YaLTeR/niri) + [Noctalia](https://docs.noctalia.dev).

## Stack

| Layer | Tool |
|---|---|
| OS | CachyOS (Arch-based) |
| Compositor | Niri (Wayland) |
| Desktop shell | Noctalia 5.x (standalone — no Quickshell) |
| Login | greetd + noctalia-greeter (optional) |
| Terminal | Alacritty |
| Shell | Fish |
| Editor | Neovim (LazyVim) · Zed · VS Code |
| Browser | Zen |
| Theme | Oxocarbon (via Noctalia templates) |

Packages come from the CachyOS repos, primarily the `cachyos-niri-noctalia` meta package
(niri, noctalia, portals, cursors, fonts). Only VS Code still needs the AUR.

## Fresh install

### 1. Prerequisites (optional)

Nearly everything lives in the CachyOS repos or gets installed automatically (see below).
An AUR helper is only needed for `visual-studio-code-bin` — it's skipped with a warning if
none is found.

```bash
sudo pacman -S --needed base-devel git
git clone https://aur.archlinux.org/paru.git && cd paru && makepkg -si
```

### 2. Run chezmoi

On a fresh machine with no chezmoi installed yet, this installs it and runs init + apply
in one line:

```bash
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- init --apply robinsmith-source
```

If chezmoi is already installed:

```bash
chezmoi init --apply https://github.com/robinsmith-source/dotfiles.git
```

Or review first with `chezmoi init` + `chezmoi diff` + `chezmoi apply` if you'd rather see
what will change before touching `$HOME`.

`chezmoi apply` does everything from here on its own — packages, a one-time machine setup,
and config validation are all wired into chezmoi's own script system (see below), no
separate install script to run.

### 3. What happens automatically

- **Bitwarden CLI** is installed before anything else runs, so templates can pull secrets
  from your vault (`.chezmoi.toml.tmpl`'s `read-source-state.pre` hook).
- **Packages** — the full list lives in `home/.chezmoidata/packages.yaml`; a
  `run_onchange_` script installs anything missing via pacman/AUR whenever that list
  changes.
- **One-time setup** (`run_once_setup.sh.tmpl`) — prompts for timezone/locale, enables
  services (docker, sshd, bluetooth, NetworkManager, power-profiles-daemon, tailscaled),
  adds you to the docker group, sets fish as the default shell, creates
  `~/Pictures/Wallpapers`, brings up Tailscale (pulling an auth key from Bitwarden if a
  "Tailscale auth key" vault item exists, otherwise just reminds you), and — on CachyOS —
  optionally offers to install/enable the `noctalia-greeter` login screen (defaults to no;
  declining keeps you starting niri from a TTY).
- **Config validation** (`run_after_validate-configs.sh`) — runs after every apply: `niri
  validate`, `noctalia config validate`, a `.pacnew` report, and a stale
  `~/.config/noctalia/settings.json` warning.
- **Git identity** — prompted once via chezmoi (`gitName`/`gitEmail`) and templated into
  `~/.gitconfig`.

### 4. Post-install

- Log out and back in for the docker group and shell change to take effect.
- Start niri from a TTY with `niri-session`, or pick it at your greeter.
- Drop wallpapers into `~/Pictures/Wallpapers`.
- See [docs.noctalia.dev](https://docs.noctalia.dev) for shell configuration.

## Noctalia 5.x config layout

Noctalia moved from JSON to TOML in 5.x:

| Path | Purpose |
|---|---|
| `~/.config/noctalia/config.toml` | user config (tracked) |
| `~/.local/state/noctalia/settings.toml` | live settings written by the Settings UI |
| `~/.config/noctalia/user-templates.toml` | theme templates (feeds nvim base16) |

`~/.config/noctalia/settings.json` is a **noctalia 4.x file and is no longer read**.
Export current state with `noctalia config export merged`.

The shell is driven by the `noctalia` binary directly — `qs -c noctalia-shell ...`
commands from the Quickshell era no longer work. Use the CLI instead:

```bash
noctalia msg dpms-off          # was: qs -c noctalia-shell ipc call monitors off
noctalia msg config-reload
noctalia config validate
```

## Updating

```bash
chezmoi update
```

Pulls the latest dotfiles and re-applies: installs any newly-added packages, re-validates
the niri and noctalia configs (so a retired config key surfaces immediately rather than as
a black screen at next login), and reports `.pacnew` files.

This does **not** upgrade already-installed packages — run `sudo pacman -Syu` (and your AUR
helper's update command) yourself when you want a full system upgrade. Keeping that manual
avoids a routine `chezmoi apply` for a config tweak turning into a surprise system upgrade.

## Managing dotfiles

`.chezmoi.toml.tmpl` enables `autoCommit` with a commit-message prompt, so any change that
touches the source directory — `chezmoi add`, `chezmoi re-add`, editing with `chezmoi edit` —
asks for a commit message and commits automatically. Push is left manual:

```bash
chezmoi status
chezmoi add ~/.config/alacritty/alacritty.toml   # prompts for a commit message, then commits
chezmoi git push
```

## Secrets

Never hardcode a real secret (API key, token, session value) into a tracked file — this repo
is public. `.chezmoi.toml.tmpl` sets `[bitwarden] unlock = "auto"`, so any `.tmpl` file can pull
a value straight from the Bitwarden vault at `chezmoi apply` time and chezmoi handles unlocking
for you:

```
{{ (bitwarden "item" "Item Name").login.password }}
```

CI also runs [gitleaks](https://github.com/gitleaks/gitleaks) on every push/PR to catch anything
that slips through before it's merged.
