#!/usr/bin/env bash
set -euo pipefail

# Use FVM if available; fallback to system flutter
if command -v fvm >/dev/null 2>&1; then
  FLUTTER=(fvm flutter)
else
  FLUTTER=(flutter)
fi

echo "Using: ${FLUTTER[*]}"

"${FLUTTER[@]}" pub get

device="chrome"
renderer="canvaskit"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--device)
      device="$2"; shift 2 ;;
    --renderer)
      renderer="$2"; shift 2 ;;
    *)
      echo "Unknown arg: $1"; exit 1 ;;
  esac
done

"${FLUTTER[@]}" run -d "$device" --web-renderer "$renderer"

