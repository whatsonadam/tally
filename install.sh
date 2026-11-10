#!/bin/bash
# Tally installer. Downloads the source and builds it on this Mac.
set -e
REPO="${1:-whatsonadam/tally}"
BASE="https://raw.githubusercontent.com/$REPO/main/source"

if ! xcode-select -p >/dev/null 2>&1; then
  echo "Installing Apple Command Line Tools. Click Install in the window, wait until it finishes,"
  echo "then paste the same line into Terminal again."
  xcode-select --install
  exit 1
fi

WORK="$(mktemp -d)"
cd "$WORK"
echo "Downloading Tally..."
for f in WorkClockApp.swift Seeds.swift build.sh; do
  curl -fsSL "$BASE/$f" -o "$f"
done
bash build.sh
cd "$HOME"
rm -rf "$WORK"
