#!/usr/bin/env bash

set -euo pipefail

if command -v niri &>/dev/null && [[ -f "$HOME/.config/niri/config.kdl" ]]; then
    niri validate && echo "niri config is valid." || echo "niri config has errors." >&2
fi

if command -v noctalia &>/dev/null; then
    noctalia config validate && echo "noctalia config is valid." || echo "noctalia config has errors." >&2
fi
