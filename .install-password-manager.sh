#!/usr/bin/env bash
set -euo pipefail

command -v bw &>/dev/null && exit 0

case "$(uname -s)" in
Linux)
    if command -v pacman &>/dev/null; then
        sudo pacman -S --needed --noconfirm bitwarden-cli
    else
        echo "install-password-manager: no supported package manager found" >&2
        exit 1
    fi
    ;;
*)
    echo "install-password-manager: unsupported OS $(uname -s)" >&2
    exit 1
    ;;
esac
