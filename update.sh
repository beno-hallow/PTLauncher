#!/bin/bash
# Pull the latest PT Launcher, rebuild, and reinstall it.
# Works as both the first-time installer and the updater.
set -euo pipefail

cd "$(dirname "$0")"

APP="PTLauncher.app"
DEST="/Applications/$APP"

# 1. Get the latest source (skip silently if this isn't a git checkout).
if [ -d .git ]; then
  echo "Fetching latest version…"
  if ! git pull --ff-only; then
    echo "git pull failed (you may have local changes). Resolve, then re-run." >&2
    exit 1
  fi
fi

# 2. Build (compiles + signs with the stable local identity).
./build.sh

# 3. Quit any running copy so the file can be replaced.
killall PTLauncher >/dev/null 2>&1 || true
sleep 1

# 4. Install into /Applications.
echo "Installing to $DEST…"
rm -rf "$DEST"
cp -R "$APP" "$DEST"

# 5. Relaunch.
open "$DEST"
echo "Done — PT Launcher updated and relaunched."
