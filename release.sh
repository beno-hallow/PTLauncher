#!/bin/bash
# Cut a signed + notarized PT Launcher release and publish it for Sparkle.
#
#   ./release.sh            # uses the version in ./VERSION
#   ./release.sh 1.2        # sets ./VERSION to 1.2 first, then releases
#
# Steps: build (Developer ID, hardened runtime) -> notarize -> staple -> zip ->
# generate signed appcast.xml -> publish to GitHub Releases -> commit appcast.
#
# One-time prerequisites (see RELEASING.md): ./setup-sparkle.sh and a stored
# notarization credential profile (default name: PTLauncher-notary).
set -euo pipefail

cd "$(dirname "$0")"

# Optional version bump from the first argument.
if [ "${1:-}" != "" ]; then
  echo "$1" > VERSION
fi
VERSION="$(cat VERSION)"

SPARKLE_DIR="Sparkle"
BIN="$SPARKLE_DIR/bin"
APP="PTLauncher.app"
NOTARY_PROFILE="${NOTARY_PROFILE:-PTLauncher-notary}"
REPO_SLUG="beno-hallow/PTLauncher"
TAG="v$VERSION"
ASSET="PTLauncher-$VERSION.zip"
DL_PREFIX="https://github.com/$REPO_SLUG/releases/download/$TAG/"

echo "=== Releasing PT Launcher $VERSION ==="

# --- 1. Build (signed, hardened runtime) ------------------------------------
./build.sh

# --- 2. Notarize ------------------------------------------------------------
echo "Submitting to Apple notary service (profile: $NOTARY_PROFILE)..."
NOTARIZE_ZIP="$(mktemp -t ptlauncher-notarize).zip"
ditto -c -k --keepParent "$APP" "$NOTARIZE_ZIP"
xcrun notarytool submit "$NOTARIZE_ZIP" --keychain-profile "$NOTARY_PROFILE" --wait
rm -f "$NOTARIZE_ZIP"

echo "Stapling notarization ticket..."
xcrun stapler staple "$APP"

# --- 3. Package the stapled app + build the signed appcast ------------------
echo "Packaging $ASSET..."
rm -rf dist
mkdir -p dist
ditto -c -k --keepParent "$APP" "dist/$ASSET"

echo "Generating appcast (signs with your Ed25519 key from the Keychain)..."
"$BIN/generate_appcast" --download-url-prefix "$DL_PREFIX" dist/
cp dist/appcast.xml ./appcast.xml

# --- 4. Publish to GitHub Releases ------------------------------------------
if command -v gh >/dev/null 2>&1; then
  echo "Creating GitHub release $TAG and uploading $ASSET..."
  gh release create "$TAG" "dist/$ASSET" \
    --repo "$REPO_SLUG" --title "PT Launcher $VERSION" \
    --notes "PT Launcher $VERSION" || \
  gh release upload "$TAG" "dist/$ASSET" --repo "$REPO_SLUG" --clobber
else
  echo
  echo "GitHub CLI (gh) not found -- finish these two steps manually:"
  echo "  1. Create a release tagged '$TAG' at https://github.com/$REPO_SLUG/releases/new"
  echo "  2. Upload dist/$ASSET as a release asset."
  echo
  read -r -p "Press Return once the asset is uploaded to continue committing the appcast... " _
fi

# --- 5. Commit + push the appcast so teammates' apps can see the update ------
echo "Committing appcast.xml and VERSION..."
git add appcast.xml VERSION sparkle_pubkey.txt 2>/dev/null || true
git commit -m "Release $VERSION" || echo "  (nothing to commit)"
git push

echo
echo "=== Released $VERSION ==="
echo "Existing installs will offer the update at their next Sparkle check (or via 'Check for Updates...')."
