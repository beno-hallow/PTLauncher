#!/bin/bash
# Builds PTLauncher.app with Sparkle embedded and signs it with your Developer ID
# (hardened runtime), ready for notarization. No Xcode project required.
#
# Prerequisites (run once): ./setup-sparkle.sh
#   - downloads Sparkle into ./Sparkle
#   - generates your Ed25519 update-signing key and writes sparkle_pubkey.txt
set -euo pipefail

cd "$(dirname "$0")"

APP="PTLauncher.app"
BIN_NAME="PTLauncher"
BUNDLE_ID="com.local.ptlauncher"

VERSION="$(cat VERSION 2>/dev/null || echo '1.0')"
SPARKLE_DIR="Sparkle"
FRAMEWORK="$SPARKLE_DIR/Sparkle.framework"

# Where the appcast lives (raw file in this repo) -- teammates' apps poll this URL.
FEED_URL="https://raw.githubusercontent.com/beno-hallow/PTLauncher/main/appcast.xml"

# Public half of the Sparkle update-signing key (safe to commit). Created by setup-sparkle.sh.
PUBKEY="$(cat sparkle_pubkey.txt 2>/dev/null || true)"

# Developer ID Application identity. Auto-detected; override with: DEV_ID="Developer ID Application: ..." ./build.sh
DEV_ID="${DEV_ID:-$(security find-identity -v -p codesigning 2>/dev/null | awk -F'"' '/Developer ID Application/{print $2; exit}')}"

# --- Preflight ---------------------------------------------------------------
if [ ! -d "$FRAMEWORK" ]; then
  echo "ERROR: $FRAMEWORK not found. Run ./setup-sparkle.sh once first." >&2
  exit 1
fi
if [ -z "$PUBKEY" ]; then
  echo "ERROR: sparkle_pubkey.txt is empty/missing. Run ./setup-sparkle.sh once first." >&2
  exit 1
fi
if [ -z "$DEV_ID" ]; then
  echo "ERROR: No 'Developer ID Application' certificate found in your keychain." >&2
  echo "       Create one in Xcode -> Settings -> Accounts -> Manage Certificates, then re-run." >&2
  exit 1
fi

# --- Compile -----------------------------------------------------------------
echo "Compiling PT Launcher v$VERSION..."
xcrun swiftc -O -o "$BIN_NAME" main.swift \
  -framework Cocoa \
  -F "$SPARKLE_DIR" -framework Sparkle \
  -Xlinker -rpath -Xlinker @executable_path/../Frameworks

# --- Assemble bundle ---------------------------------------------------------
echo "Assembling $APP..."
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APP/Contents/Frameworks"
mv "$BIN_NAME" "$APP/Contents/MacOS/$BIN_NAME"
cp -R "$FRAMEWORK" "$APP/Contents/Frameworks/"

# Bundle the preloaded scripts. On first launch the app copies these into
# ~/Library/Application Support/PTLauncher/scripts/ and pre-wires a button for each.
if [ -d default_scripts ] && ls default_scripts/*.applescript >/dev/null 2>&1; then
  mkdir -p "$APP/Contents/Resources/scripts"
  cp default_scripts/*.applescript "$APP/Contents/Resources/scripts/"
  echo "Bundled $(ls default_scripts/*.applescript | wc -l | tr -d ' ') default script(s)."
fi

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>PT Launcher</string>
    <key>CFBundleDisplayName</key><string>PT Launcher</string>
    <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
    <key>CFBundleVersion</key><string>$VERSION</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleExecutable</key><string>$BIN_NAME</string>
    <key>LSMinimumSystemVersion</key><string>11.0</string>
    <key>LSUIElement</key><true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>PT Launcher sends menu commands and keystrokes to Pro Tools and other apps you configure.</string>
    <key>SUFeedURL</key><string>$FEED_URL</string>
    <key>SUPublicEDKey</key><string>$PUBKEY</string>
    <key>SUEnableAutomaticChecks</key><true/>
    <key>SUScheduledCheckInterval</key><integer>86400</integer>
</dict>
</plist>
PLIST

# Entitlement: a hardened-runtime app must declare this to send Apple events
# (PT Launcher drives Pro Tools / System Events via AppleScript).
ENT="$(mktemp -t ptlauncher-ent).plist"
cat > "$ENT" <<ENTITLEMENTS
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.automation.apple-events</key><true/>
</dict>
</plist>
ENTITLEMENTS

# --- Code signing (Developer ID + hardened runtime) --------------------------
# Sparkle docs: sign the nested helpers/XPC services first (deepest first),
# then the framework, then the app. Hardened runtime + secure timestamp are
# required for notarization. See https://sparkle-project.org/documentation/
echo "Signing with: $DEV_ID"
SPK="$APP/Contents/Frameworks/Sparkle.framework"

# Re-sign Sparkle's nested helpers with your identity, PRESERVING their own
# entitlements -- Downloader.xpc is sandboxed, and stripping its entitlements
# breaks the update download.
signnested() { codesign --force --options runtime --timestamp --preserve-metadata=entitlements --sign "$DEV_ID" "$@"; }
for p in \
  "$SPK/Versions/B/XPCServices/Installer.xpc" \
  "$SPK/Versions/B/XPCServices/Downloader.xpc" \
  "$SPK/Versions/B/Autoupdate" \
  "$SPK/Versions/B/Updater.app" ; do
  [ -e "$p" ] && signnested "$p"
done
# The framework wrapper itself has no entitlements to preserve.
codesign --force --options runtime --timestamp --sign "$DEV_ID" "$SPK"
# Main app carries the apple-events entitlement.
codesign --force --options runtime --timestamp --entitlements "$ENT" --sign "$DEV_ID" "$APP"
rm -f "$ENT"

echo "Verifying..."
codesign --verify --deep --strict --verbose=2 "$APP" || echo "  (verify reported issues -- see above)"

echo
echo "Done: $(pwd)/$APP  (v$VERSION)"
echo "For a full signed+notarized release, run ./release.sh instead."
