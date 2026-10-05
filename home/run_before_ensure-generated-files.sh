#!/usr/bin/env bash
set -euo pipefail

# Noctalia generates these at runtime and they are not tracked. niri refuses to
# load its config when an include is missing, so make sure the file exists.
mkdir -p "$HOME/.config/niri"
touch "$HOME/.config/niri/noctalia.kdl"
