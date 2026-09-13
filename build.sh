#!/bin/bash
set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP="/Users/dm0m/Applications/Clipboard History.app"

pkill -f "Clipboard History.app/Contents/MacOS/ClipboardHistory" 2>/dev/null || true
sleep 0.3

swift build -c release --package-path "$DIR"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$DIR/Info.plist" "$APP/Contents/Info.plist"
cp "$DIR/Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
cp "$DIR/.build/release/ClipboardHistory" "$APP/Contents/MacOS/ClipboardHistory"
chmod +x "$APP/Contents/MacOS/ClipboardHistory"

codesign --force --deep --sign - "$APP"

echo "Built and installed: $APP"
open "$APP"
