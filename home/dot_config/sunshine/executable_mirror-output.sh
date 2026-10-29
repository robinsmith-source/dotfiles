#!/bin/sh
set -eu

src=DP-1
rules="${XDG_CONFIG_HOME:-$HOME/.config}/umbriel/sunshine-mirror.toml"

current_width() {
  umbriel outputs --json | jq -r --arg out "$src" '.[] | select(.name == $out) | .logical_size.width'
}

case "$1" in
prepare)
  # A leftover virtual output would be captured instead of DP-1
  umbriel output-destroy sunshine >/dev/null 2>&1 || true

  fps="${SUNSHINE_CLIENT_FPS:-60}"
  [ "$fps" -gt 120 ] && fps=120
  printf '[output.%s]\nmode = "2560x1440@%s"\n' "$src" "$fps" >"$rules"
  umbriel msg config-reload >/dev/null
  # Wait for the modeset, so capture starts at the new size
  i=0
  while [ "$i" -lt 50 ]; do
    [ "$(current_width)" = 2560 ] && break
    sleep 0.1
    i=$((i + 1))
  done
  ;;
restore)
  : >"$rules"
  umbriel msg config-reload >/dev/null
  ;;
esac
