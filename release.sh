#!/bin/bash
# For the maker only (needs Xcode). Builds one Tally.app that works on every Mac, as Tally.zip.
set -e
cd "$(dirname "$0")"
rm -rf release
mkdir -p release/Tally.app/Contents/MacOS
for A in arm64 x86_64; do
  echo "Building $A..."
  swiftc -O -parse-as-library -module-name Tally -target "$A-apple-macos13.0" \
    -o "release/Tally-$A" WorkClockApp.swift Seeds.swift
done
lipo -create release/Tally-arm64 release/Tally-x86_64 -output release/Tally.app/Contents/MacOS/Tally
sed -n "/<<'PLIST'/,/^PLIST/p" build.sh | sed '1d;$d' > release/Tally.app/Contents/Info.plist
codesign --force --deep --sign - release/Tally.app
rm -f Tally.zip
ditto -c -k --keepParent release/Tally.app Tally.zip
rm -rf release
echo "Done. Upload Tally.zip as a GitHub Release."
