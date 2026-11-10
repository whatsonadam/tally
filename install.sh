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
if curl -fsSL "$BASE/build.sh" -o build.sh 2>/dev/null; then
  for f in WorkClockApp.swift Seeds.swift; do
    curl -fsSL "$BASE/$f" -o "$f"
  done
else
  # Some networks block raw.githubusercontent.com. github.com itself usually works.
  echo "Trying another way..."
  git clone --depth 1 "https://github.com/$REPO" repo
  cp repo/source/* .
fi
bash build.sh
cd "$HOME"
rm -rf "$WORK"
