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

Nearly everything now lives in the CachyOS repos. An AUR helper is only needed for
`visual-studio-code-bin` — `install.sh` skips AUR packages with a warning if none is found.

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

Use `bash <(curl ...)`, not `curl ... | bash` — the latter breaks the interactive prompts.

The script installs packages, enables services (docker, sshd, bluetooth, NetworkManager,
power-profiles-daemon, tailscaled), sets your Git identity and timezone/locale, makes fish
the default shell, creates `~/Pictures/Wallpapers`, and validates both configs at the end.

Three prompts default to **no** and are safe to decline:

- **Removing `cachyos-desktop-settings`** — it conflicts with `cachyos-niri-noctalia`.
  Declining aborts the install rather than leaving a half-applied state.
- **Installing `noctalia-greeter`** — the greetd login screen.
- **Enabling greetd** — this swaps your login path. Decline to keep starting niri from a TTY.

### 4. Post-install

- Log out and back in for the docker group and shell change to take effect.
- Start niri from a TTY with `niri-session`, or pick it at your greeter.
- Drop wallpapers into `~/Pictures/Wallpapers`.
- Run `sudo tailscale up` to finish Tailscale setup (the Noctalia plugin depends on it).
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
bash ~/update.sh
```

Pulls the latest dotfiles, updates system packages (pacman + AUR), then:

- validates the niri and noctalia configs, so a retired config key surfaces immediately
  rather than as a black screen at next login
- reports any `.pacnew` files left to merge
- flags leftover `settings.json` / stale `qs -c noctalia-shell` commands
- reloads Noctalia in place when it was upgraded, and tells you when niri needs a re-login

## Managing dotfiles

Once checked out, `.config/fish/functions/dotfiles.fish` provides a `dotfiles` function
scoped to the bare repo (the `dots` alias above is only needed before the first checkout):

```bash
dotfiles status
dotfiles add ~/.config/alacritty/alacritty.toml
dotfiles commit -m "feat: update alacritty config"
dotfiles push
```

Note that `.config/nvim/lua/matugen.lua` is **generated** by the Noctalia template hook on
every theme change, so it shows as modified regularly. Commit it deliberately rather than
sweeping it in with `dotfiles add -A`.
