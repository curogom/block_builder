#!/usr/bin/env bash
set -euo pipefail

if command -v fvm >/dev/null 2>&1; then
  FLUTTER=(fvm flutter)
else
  FLUTTER=(flutter)
fi

echo "Using: ${FLUTTER[*]}"

"${FLUTTER[@]}" pub get
renderer="canvaskit"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --renderer)
      renderer="$2"; shift 2 ;;
    *)
      echo "Unknown arg: $1"; exit 1 ;;
  esac
done

"${FLUTTER[@]}" build web --web-renderer "$renderer"

echo "Build complete: build/web"

