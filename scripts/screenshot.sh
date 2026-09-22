#!/usr/bin/env bash
# Stage a showcase workspace (nvim + fastfetch + btop), screenshot it and publish it to the
# `screenshots` branch that the README embeds.
#
#   scripts/screenshot.sh           take + publish
#   scripts/screenshot.sh --local   take only, print the file path
#   SCREENSHOT=1 git push           take + publish from the pre-push hook
set -euo pipefail

if [[ ${1:-} == --on-push ]]; then
    [[ -n ${SCREENSHOT:-} ]] || exit 0
fi
[[ -n ${NIRI_SOCKET:-} ]] || {
    echo "screenshot: not running inside niri, skipping" >&2
    exit 0
}

OUTPUT=${SCREENSHOT_OUTPUT:-DP-1}
REPO=$(git rev-parse --show-toplevel)
SHOT="$(mktemp -d)/screenshot.png"

prev_output=$(niri msg -j focused-output | jq -r .name)
prev_ws=$(niri msg -j workspaces | jq -r '.[] | select(.is_focused) | .idx')

cleanup() {
    niri msg -j windows |
        jq -r '.[] | select(.app_id // "" | startswith("showcase-")) | .id' |
        while read -r id; do niri msg action close-window --id "$id"; done
    niri msg action focus-monitor "$prev_output"
    niri msg action focus-workspace "$prev_ws"
}
trap cleanup EXIT

wait_for() { # wait_for <app-id>, until it exists and has focus
    for _ in {1..50}; do
        niri msg -j windows | jq -e --arg id "$1" 'any(.[]; .app_id == $id and .is_focused)' >/dev/null && return
        sleep 0.1
    done
    echo "screenshot: timed out waiting for $1" >&2
    exit 1
}

spawn() { # spawn <app-id> <command...>
    niri msg action spawn -- alacritty --class "$1" --working-directory "$REPO" -e "${@:2}"
    wait_for "$1"
}

# The last workspace on an output is always empty in niri.
niri msg action focus-monitor "$OUTPUT"
empty_ws=$(niri msg -j workspaces | jq -r --arg o "$OUTPUT" '[.[] | select(.output == $o)] | max_by(.idx) | .idx')
niri msg action focus-workspace "$empty_ws"

# Left column: nvim. Right column: fastfetch stacked above btop.
spawn showcase-nvim nvim home/dot_config/niri/cfg/keybinds.kdl
niri msg action set-column-width 50%
spawn showcase-fetch fish -C fastfetch
spawn showcase-btop btop --preset 4 # cpu + mem only, no process list or IPs
niri msg action consume-or-expel-window-left
niri msg action set-column-width 50%
niri msg action focus-column-first
niri msg action center-visible-columns

sleep "${SCREENSHOT_DELAY:-3}" # let nvim load plugins and btop draw a few samples
niri msg action screenshot-screen --show-pointer false --path "$SHOT"
for _ in {1..50}; do
    [[ -s $SHOT ]] && break
    sleep 0.1
done
[[ -s $SHOT ]] || {
    echo "screenshot: niri did not write $SHOT" >&2
    exit 1
}

if [[ ${1:-} == --local ]]; then
    echo "$SHOT"
    exit 0
fi

# Single orphan commit, force-pushed, so the branch never accumulates old images.
blob=$(git hash-object -w "$SHOT")
tree=$(printf '100644 blob %s\tscreenshot.png\n' "$blob" | git mktree)
commit=$(git commit-tree "$tree" -m "chore: update screenshot")
git push --no-verify --force --quiet origin "$commit:refs/heads/screenshots"
rm -f "$SHOT"
echo "screenshot: published to the screenshots branch"
