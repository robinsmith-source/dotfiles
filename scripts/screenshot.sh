#!/usr/bin/env bash
# Usage: screenshot.sh              capture and print the image path
#        screenshot.sh --publish    push the captured image to the screenshots branch
set -euo pipefail

REPO=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
SHOT=${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/screenshot.png
OUTPUT=DP-1
SETTLE=0.5

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

if [[ -n ${UMBRIEL_SOCKET:-} || ${XDG_CURRENT_DESKTOP:-} == umbriel ]]; then
    wm_workspaces() { umbriel workspaces --json; }
    prev_output=$(wm_workspaces | jq -r '.[] | select(.focused) | .output')
    prev_ws=$(wm_workspaces | jq '.[] | select(.focused) | .index')
    focused() { umbriel focused-window --json 2>/dev/null | jq -r '.id // empty' || true; }
    close_window() { umbriel msg window-close "$1"; }
    focus_workspace() { umbriel msg workspace-switch "$2" --output "$1"; }
    run() { umbriel msg spawn "$(printf '%q ' "$@")"; }
    third_width() { umbriel msg window-set-primary-extent 0.33333; }
    stack_left() { umbriel msg window-consume-or-expel-left; }
    to_last() { umbriel msg column-move-to-last; }
    focus_first() { umbriel msg column-focus-first; }
    capture() {
        local tmp
        tmp=$(mktemp -d)
        noctalia msg screenshot-fullscreen --save-to-file --no-copy-to-clipboard \
            --no-pipe-to-command --no-freeze-screen --no-show-cursor --no-annotate \
            --directory "$tmp" --format png "$OUTPUT"
        for _ in {1..50}; do compgen -G "$tmp/*.png" >/dev/null && break; sleep 0.1; done
        sleep 0.5
        mv "$tmp"/*.png "$SHOT" && rmdir "$tmp"
    }
else
    wm_workspaces() { niri msg -j workspaces | jq 'map(.index = .idx | .focused = .is_focused)'; }
    prev_output=$(niri msg -j focused-output | jq -r .name)
    prev_ws=$(wm_workspaces | jq '.[] | select(.focused) | .index')
    focused() { niri msg -j focused-window | jq -r '.id // empty'; }
    close_window() { niri msg action close-window --id "$1"; }
    focus_workspace() {
        niri msg action focus-monitor "$1"
        niri msg action focus-workspace "$2"
    }
    run() { niri msg action spawn -- "$@"; }
    third_width() { niri msg action set-column-width 33.333%; }
    stack_left() { niri msg action consume-or-expel-window-left; }
    to_last() { niri msg action move-column-to-last; }
    focus_first() {
        niri msg action focus-column-first
        niri msg action center-visible-columns
    }
    capture() { niri msg action screenshot-screen --show-pointer false --path "$SHOT"; }
fi

# A short symlink keeps the long checkout path out of Luciole's breadcrumb
LINK=$HOME/dotfiles
ln -sfn "$REPO" "$LINK"

cleanup() {
    rm -f "$LINK"
    for id in "${IDS[@]}"; do
        close_window "$id"
    done
    focus_workspace "$prev_output" "$prev_ws"
}
trap cleanup EXIT

spawn_app() {
    local prev
    prev=$(focused)
    run "$@"
    until [[ $(focused) != "$prev" ]]; do sleep 0.1; done
    IDS+=("$(focused)")
    settle
}

settle() { sleep "$SETTLE"; }

spawn() { spawn_app alacritty --working-directory "$REPO" "$@"; }

focus_workspace "$OUTPUT" "$(wm_workspaces | jq --arg o "$OUTPUT" '[.[] | select(.output == $o) | .index] | max')"

spawn --class showcase-nvim -e nvim
third_width
settle
spawn
third_width
settle
spawn --class showcase-btop -e btop
stack_left
settle
# ShowItems opens a Luciole window on the folder with the README selected, so its preview is shown
spawn_app gdbus call --session --dest org.freedesktop.FileManager1 \
    --object-path /org/freedesktop/FileManager1 \
    --method org.freedesktop.FileManager1.ShowItems "['file://$LINK/README.md']" ""
to_last
settle
third_width
settle
focus_first
settle

sleep 2
mkdir -p "$(dirname "$SHOT")"
rm -f "$SHOT"
capture
[[ -s $SHOT ]]
echo "$SHOT"
