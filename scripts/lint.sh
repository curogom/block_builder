#!/usr/bin/env bash
set -euo pipefail

if command -v fvm >/dev/null 2>&1; then
  FLUTTER=(fvm flutter)
else
  FLUTTER=(flutter)
fi

echo "Using: ${FLUTTER[*]} analyze"
"${FLUTTER[@]}" analyze

