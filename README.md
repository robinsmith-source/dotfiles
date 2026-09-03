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

`chezmoi apply` handles everything on its own via the `run_*` scripts under `home/`:

- a `read-source-state.pre` hook downloads the standalone Bitwarden CLI (`bw`) into
  `/usr/local/bin` before anything else runs, since templates may need it
- `run_onchange_install-packages.sh` installs packages from `home/.chezmoidata/packages.yaml`
  (prompts before installing anything) whenever that list changes
- `run_once_setup-greeter.sh` (CachyOS only) offers to install/enable the `noctalia-greeter`
  login screen — defaults to no
- `run_after_setup-pre-commit.sh` runs `pre-commit install` in this repo after every apply
  (`pre-commit` itself is installed via `packages.yaml`)
- `run_after_validate-configs.sh` validates the niri/noctalia configs and reports `.pacnew`
  files after every apply

Git identity (`gitName`/`gitEmail`) is prompted once via chezmoi and templated into
`~/.gitconfig`, which also signs commits with your SSH key via the Bitwarden SSH agent
(`gpg.ssh.defaultKeyCommand`) — register the key from `ssh-add -L` as a **signing key** (not
just an auth key) in GitHub for the "Verified" badge.

## Update

```bash
chezmoi update
```

Pulls the latest dotfiles, re-applies, and installs any newly-added packages. Does not upgrade
already-installed packages — run `sudo pacman -Syu` for that.

## Secrets

Never hardcode real secrets or personal info into tracked files — this repo is public.
`.tmpl` files can pull values from Bitwarden instead:

```
{{ (bitwarden "item" "Item Name").login.password }}
```

Two layers catch anything that slips through:

- [pre-commit](https://pre-commit.com) runs locally before a commit is even made — gitleaks,
  shellcheck, shfmt, and basic YAML/TOML/JSON sanity checks. Installed automatically by
  `run_after_setup-pre-commit.sh`
- CI re-runs the same pre-commit checks (`lint` job) plus a dedicated gitleaks scan and
  [trufflehog](https://github.com/trufflesecurity/trufflehog) (`secret-scan` job) as a backstop
  — on every push/PR, and weekly on a schedule in case nothing gets pushed for a while

`.gitleaks.toml` extends the default ruleset with a custom rule for known personal PII (e.g. a
home address that leaked once already) that wouldn't otherwise match a generic secret pattern.
