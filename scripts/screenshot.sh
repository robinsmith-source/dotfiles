#!/usr/bin/env bash
# Usage: screenshot.sh              capture and print the image path
#        screenshot.sh --publish    push the captured image to the screenshots branch
set -euo pipefail

REPO=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
SHOT=${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/screenshot.png
OUTPUT=DP-1

if [[ ${1:-} == --publish ]]; then
    [[ -s $SHOT ]] || {
        echo "nothing to publish, capture one first" >&2
        exit 1
    }
    blob=$(git -C "$REPO" hash-object -w "$SHOT")
    tree=$(printf '100644 blob %s\tscreenshot.png\n' "$blob" | git -C "$REPO" mktree)
    commit=$(git -C "$REPO" commit-tree "$tree" -m "chore: update screenshot")
    git -C "$REPO" push -f -q origin "$commit:refs/heads/screenshots"
    exit 0
fi

IDS=()
prev_output=$(niri msg -j focused-output | jq -r .name)
prev_ws=$(niri msg -j workspaces | jq '.[] | select(.is_focused) | .idx')

cleanup() {
    for id in "${IDS[@]}"; do
        niri msg action close-window --id "$id"
    done
    niri msg action focus-monitor "$prev_output"
    niri msg action focus-workspace "$prev_ws"
}
trap cleanup EXIT

focused() { niri msg -j focused-window | jq -r .id; }

spawn() {
    local prev
    prev=$(focused)
    niri msg action spawn -- alacritty --working-directory "$REPO" "$@"
    until [[ $(focused) != "$prev" ]]; do sleep 0.1; done
    IDS+=("$(focused)")
}

niri msg action focus-monitor "$OUTPUT"
niri msg action focus-workspace "$(niri msg -j workspaces | jq --arg o "$OUTPUT" '[.[] | select(.output == $o) | .idx] | max')"

spawn --class showcase-nvim -e nvim
niri msg action set-column-width 33.333%
spawn
niri msg action set-column-width 33.333%
spawn --class showcase-btop -e btop
niri msg action consume-or-expel-window-left
spawn --class showcase-cliamp -e cliamp --auto-play
niri msg action set-column-width 33.333%
niri msg action focus-column-first
niri msg action center-visible-columns

sleep 3
mkdir -p "$(dirname "$SHOT")"
rm -f "$SHOT"
niri msg action screenshot-screen --show-pointer false --path "$SHOT"
[[ -s $SHOT ]]
echo "$SHOT"
