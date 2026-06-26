#!/bin/bash
# Builds PTLauncher.app from main.swift — no Xcode project required.
# Requires the Xcode command-line tools (run: xcode-select --install).
set -euo pipefail

cd "$(dirname "$0")"

APP="PTLauncher.app"
BIN_NAME="PTLauncher"
BUNDLE_ID="com.local.ptlauncher"
CERT_CN="PT Launcher Local Cert"   # stable self-signed identity

# Create a per-user self-signed code-signing certificate once, then sign every
# build with that SAME identity. This is what lets macOS remember the
# Accessibility/Automation permissions you grant — ad-hoc signing changes the
# app's identity on every build and forces you to re-grant them each update.
ensure_signing_identity() {
  if security find-certificate -c "$CERT_CN" >/dev/null 2>&1; then
    return 0
  fi
  echo "Creating local signing certificate \"$CERT_CN\" (one time)…"
  local tmp; tmp="$(mktemp -d)"
  cat > "$tmp/cfg" <<CFG
[req]
distinguished_name = dn
x509_extensions = ext
prompt = no
[dn]
CN = $CERT_CN
[ext]
basicConstraints = critical,CA:FALSE
keyUsage = critical,digitalSignature
extendedKeyUsage = critical,codeSigning
CFG
  openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
    -keyout "$tmp/key.pem" -out "$tmp/cert.pem" -config "$tmp/cfg" >/dev/null 2>&1 || true
  openssl pkcs12 -export -inkey "$tmp/key.pem" -in "$tmp/cert.pem" \
    -name "$CERT_CN" -out "$tmp/id.p12" -passout pass: >/dev/null 2>&1 || true
  security import "$tmp/id.p12" -k "$HOME/Library/Keychains/login.keychain-db" \
    -P "" -A -T /usr/bin/codesign >/dev/null 2>&1 || true
  rm -rf "$tmp"
}

echo "Compiling…"
xcrun swiftc -O -o "$BIN_NAME" main.swift -framework Cocoa

echo "Assembling ${APP}..."
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"
mv "$BIN_NAME" "$APP/Contents/MacOS/$BIN_NAME"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>PT Launcher</string>
    <key>CFBundleDisplayName</key>
    <string>PT Launcher</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>$BIN_NAME</string>
    <key>LSMinimumSystemVersion</key>
    <string>11.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>PT Launcher sends menu commands and keystrokes to Pro Tools and other apps you configure.</string>
</dict>
</plist>
PLIST

# Sign with the stable local identity (falls back to ad-hoc if unavailable).
ensure_signing_identity
echo "Code signing…"
if security find-certificate -c "$CERT_CN" >/dev/null 2>&1 \
   && codesign --force --deep --sign "$CERT_CN" "$APP" 2>/dev/null; then
  echo "  signed with \"$CERT_CN\" — granted permissions will persist across updates"
else
  codesign --force --deep --sign - "$APP" 2>/dev/null || true
  echo "  signed ad-hoc — you may need to re-grant permissions after an update"
fi

echo
echo "Done. Built: $(pwd)/$APP"
echo "Move it to /Applications and double-click to run:"
echo "    mv \"$(pwd)/$APP\" /Applications/"
