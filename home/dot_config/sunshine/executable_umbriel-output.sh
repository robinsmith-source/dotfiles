#!/bin/sh
set -eu

name=sunshine
rules="${XDG_CONFIG_HOME:-$HOME/.config}/umbriel/sunshine.toml"

case "$1" in
create)
  umbriel output-destroy "$name" >/dev/null 2>&1 || true
  umbriel output-create "$name" \
    "${SUNSHINE_CLIENT_WIDTH:-1920}x${SUNSHINE_CLIENT_HEIGHT:-1080}@${SUNSHINE_CLIENT_FPS:-60}" >/dev/null

  # Block until the compositor has actually registered and mapped the output
  i=0
  while [ "$i" -lt 50 ]; do
    if umbriel outputs --json | jq -e --arg name "$name" 'any(.[]; .name == $name)' >/dev/null 2>&1; then
      break
    fi
    sleep 0.05
    i=$((i + 1))
  done

  # Closing Big Picture maps Steam's main window again; keep it from stealing
  # focus and switching a physical monitor's workspace.
  cat >"$rules" <<'RULES'
[[window_rule]]
match.app_id = "^steam$"
match.title = "^[Ss]team$"
default_focused = false
RULES
  umbriel msg config-reload >/dev/null
  ;;
remove)
  # Give windows that the app's undo command is closing up to 5 seconds to
  # go away, so they do not flash onto a physical monitor.
  i=0
  while [ "$i" -lt 25 ]; do
    left="$(umbriel windows --json |
      jq --arg out "$name:" '[.[] | select(.workspace | startswith($out))] | length')"
    [ "$left" = 0 ] && break
    sleep 0.2
    i=$((i + 1))
  done
  # Move what is left to the focused workspace of another output, so it does
  # not return to the next session's output: umbriel remembers the output a
  # window came from and moves it back when one with the same name reappears.
  target="$(umbriel workspaces --json |
    jq -r --arg out "$name" '[.[] | select(.output != $out and .active)]
                | (map(select(.focused)) + .) | first | "\(.name)/\(.output)" // empty')"
  for id in $(umbriel windows --json |
    jq -r --arg out "$name:" '.[] | select(.workspace | startswith($out)) | .id'); do
    [ -n "$target" ] || break
    umbriel msg "window-focus:$id"
    umbriel msg "window-move-to-workspace-silent:$target"
  done
  umbriel output-destroy "$name" >/dev/null 2>&1 || true

  : >"$rules"
  umbriel msg config-reload >/dev/null
  ;;
esac
