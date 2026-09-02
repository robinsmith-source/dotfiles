#!/usr/bin/env bash
# A niri or noctalia upgrade can retire config keys. Catch it here rather than at
# next login, when a broken config drops you to a black screen.
set -euo pipefail

if command -v niri &>/dev/null && [[ -f "$HOME/.config/niri/config.kdl" ]]; then
    niri validate && echo "niri config is valid." || echo "niri config has errors (see above)." >&2
fi

if command -v noctalia &>/dev/null; then
    noctalia config validate || echo "noctalia config has errors (see above)." >&2
fi

# noctalia 5.x moved from settings.json to TOML. A leftover settings.json is inert
# and quietly out of date, which is worse than absent.
if [[ -f "$HOME/.config/noctalia/settings.json" ]]; then
    echo "~/.config/noctalia/settings.json is a noctalia 4.x file and is no longer read." >&2
    echo "  Live settings now live in ~/.local/state/noctalia/settings.toml" >&2
fi

# cachyos-niri-noctalia ships defaults under /etc/skel and /etc/dconf; upstream
# changes land as .pacnew rather than overwriting, so surface them.
pacnew=$(find /etc -name '*.pacnew' 2>/dev/null || true)
if [[ -n $pacnew ]]; then
    echo "$(wc -l <<<"$pacnew") .pacnew file(s) to merge:" >&2
    while IFS= read -r f; do printf '  · %s\n' "$f" >&2; done <<<"$pacnew"
fi
