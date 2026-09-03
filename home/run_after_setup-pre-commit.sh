#!/usr/bin/env bash
set -euo pipefail

command -v pre-commit &>/dev/null || exit 0

cd "$HOME/.local/share/chezmoi"
pre-commit install
