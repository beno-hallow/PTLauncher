#!/bin/bash
# One-time maintainer setup for Sparkle auto-updates.
#   1. Downloads the Sparkle framework + tools into ./Sparkle
#   2. Generates your Ed25519 update-signing key (private key stored in your
#      login Keychain -- it never touches the repo) and writes the PUBLIC key
#      to sparkle_pubkey.txt (safe to commit).
#
# Run this once per maintainer machine. Bump SPARKLE_VERSION if you want a newer
# Sparkle: see https://github.com/sparkle-project/Sparkle/releases
set -euo pipefail

cd "$(dirname "$0")"

SPARKLE_VERSION="${SPARKLE_VERSION:-2.6.4}"
SPARKLE_DIR="Sparkle"
TARBALL="Sparkle-$SPARKLE_VERSION.tar.xz"
URL="https://github.com/sparkle-project/Sparkle/releases/download/$SPARKLE_VERSION/$TARBALL"

# --- 1. Download + extract Sparkle ------------------------------------------
if [ -d "$SPARKLE_DIR/Sparkle.framework" ]; then
  echo "Sparkle already present at $SPARKLE_DIR/ -- skipping download."
else
  echo "Downloading Sparkle $SPARKLE_VERSION..."
  tmp="$(mktemp -d)"
  curl -fsSL "$URL" -o "$tmp/$TARBALL"
  mkdir -p "$SPARKLE_DIR"
  tar -xJf "$tmp/$TARBALL" -C "$SPARKLE_DIR"
  rm -rf "$tmp"
  echo "Extracted to $SPARKLE_DIR/"
fi

# The release tarball contains Sparkle.framework and a bin/ folder with the tools.
BIN="$SPARKLE_DIR/bin"
if [ ! -x "$BIN/generate_keys" ]; then
  echo "ERROR: $BIN/generate_keys not found. Check the Sparkle download." >&2
  exit 1
fi

# --- 2. Generate / read the update-signing key ------------------------------
echo "Ensuring an Ed25519 update-signing key exists (stored in your Keychain)..."
# Idempotent: creates the key on first run, no-op afterward. May prompt once for
# Keychain access -- approve it.
"$BIN/generate_keys" >/dev/null 2>&1 || true

echo "Writing public key to sparkle_pubkey.txt..."
"$BIN/generate_keys" -p > sparkle_pubkey.txt

echo
echo "Done."
echo "  * Public key (committed):   $(cat sparkle_pubkey.txt)"
echo "  * Private key:              stored in your login Keychain only -- DO NOT export or commit it."
echo
echo "Next: commit sparkle_pubkey.txt, then cut a release with ./release.sh."
echo "Also set up your notarization credential once (see RELEASING.md):"
echo "  xcrun notarytool store-credentials PTLauncher-notary --apple-id <you@apple> --team-id <TEAMID> --password <app-specific-password>"
