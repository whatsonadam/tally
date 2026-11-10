#!/bin/bash
# Tally installer.
set -e
REPO="${1:-whatsonadam/tally}"
APPS="$HOME/Applications"

# 1. Ready-made app from the latest release. No tools needed.
TMP="$(mktemp -d)"
if curl -fsSL "https://github.com/$REPO/releases/latest/download/Tally.zip" -o "$TMP/Tally.zip" 2>/dev/null; then
  echo "Installing Tally..."
  pkill -x Tally 2>/dev/null || true
  pkill -x WorkClock 2>/dev/null || true
  mkdir -p "$APPS"
  rm -rf "$APPS/Tally.app" "$APPS/WorkClock.app"
  ditto -x -k "$TMP/Tally.zip" "$APPS"
  xattr -cr "$APPS/Tally.app" 2>/dev/null || true
  rm -rf "$TMP"
  echo "Done. Opening Tally (it will also open at login)."
  open "$APPS/Tally.app"
  exit 0
fi

# 2. Fallback: build it on this Mac. This needs Xcode.
if ! xcodebuild -version >/dev/null 2>&1; then
  echo "Could not download Tally and Xcode is not installed to build it."
  echo "Please check your internet connection and try again, or ask Gil."
  exit 1
fi
BASE="https://raw.githubusercontent.com/$REPO/main/source"
cd "$TMP"
if curl -fsSL "$BASE/build.sh" -o build.sh 2>/dev/null; then
  for f in WorkClockApp.swift Seeds.swift; do curl -fsSL "$BASE/$f" -o "$f"; done
else
  git clone --depth 1 "https://github.com/$REPO" repo
  cp repo/source/* .
fi
bash build.sh
cd "$HOME"
rm -rf "$TMP"
