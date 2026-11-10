#!/bin/bash
# Builds Tally on your own Mac. Needs Xcode (the Command Line Tools alone are not enough).
set -e
cd "$(dirname "$0")"

if ! xcode-select -p >/dev/null 2>&1; then
  echo "Installing Apple Command Line Tools. Click Install in the window that appears, then run this again."
  xcode-select --install
  exit 1
fi

APP="build/Tally.app"
rm -rf build
mkdir -p "$APP/Contents/MacOS"

# Your personal edition has Logos.swift. The shared edition has Seeds.swift.
if [ -f Logos.swift ]; then EXTRA="Logos.swift"; else EXTRA="Seeds.swift"; fi

echo "Building..."
swiftc -O -parse-as-library -module-name Tally \
  -target "$(uname -m)-apple-macos13.0" \
  -o "$APP/Contents/MacOS/Tally" \
  WorkClockApp.swift "$EXTRA"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>local.workclock.app</string>
  <key>CFBundleName</key><string>Tally</string>
  <key>CFBundleDisplayName</key><string>Tally</string>
  <key>CFBundleExecutable</key><string>Tally</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST

codesign --force --deep --sign - "$APP"

mkdir -p "$HOME/Applications"
# Close and remove older versions, including the one that was called WorkClock.
pkill -x Tally 2>/dev/null || true
pkill -x WorkClock 2>/dev/null || true
rm -rf "$HOME/Applications/Tally.app" "$HOME/Applications/WorkClock.app"
cp -R "$APP" "$HOME/Applications/"
echo "Done. Opening Tally from ~/Applications (it will also open at login)."
open "$HOME/Applications/Tally.app"
