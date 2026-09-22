#!/usr/bin/env bash

set -euo pipefail

if command -v niri &>/dev/null && [[ -f "$HOME/.config/niri/config.kdl" ]]; then
    if niri validate; then
        echo "niri config is valid."
    else
        echo "niri config has errors." >&2
    fi
fi

if command -v noctalia &>/dev/null; then
    if noctalia config validate; then
        echo "noctalia config is valid."
    else
        echo "noctalia config has errors." >&2
    fi
fi
