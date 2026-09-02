#!/usr/bin/env bash
set -euo pipefail

command -v bw &>/dev/null && exit 0

case "$(uname -s)" in
Linux)
    tmpdir=$(mktemp -d)
    if curl -fsSL "https://bitwarden.com/download/?app=cli&platform=linux" -o "$tmpdir/bw.zip" \
        && unzip -oq "$tmpdir/bw.zip" -d "$tmpdir"; then
        sudo install -Dm755 "$tmpdir/bw" /usr/local/bin/bw
    else
        echo "install-password-manager: failed to download bw — install it manually into \$PATH" >&2
    fi
    rm -rf "$tmpdir"
    ;;
*)
    echo "install-password-manager: unsupported OS $(uname -s)" >&2
    ;;
esac

exit 0
