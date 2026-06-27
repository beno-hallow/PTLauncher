#!/bin/bash
# dev.sh -- kill any running dev instance, recompile, and relaunch.
# Usage:
#   ./dev.sh          -- build and run
#   ./dev.sh watch    -- rebuild+rerun every time main.swift is saved (requires fswatch)
set -euo pipefail
cd "$(dirname "$0")"

BIN="./.build_dev/PTLauncher"
mkdir -p .build_dev

_kill() {
    pkill -x PTLauncher 2>/dev/null || true
}

_build() {
    echo "> Compiling..."
    xcrun swiftc -O -o "$BIN" main.swift -framework Cocoa
    echo "[ok] Done"
}

_run() {
    echo "> Launching..."
    "$BIN" &
    disown
    echo "  PID $! (script will exit; app keeps running)"
}

_kill
_build
_run

if [[ "${1:-}" == "watch" ]]; then
    if ! command -v fswatch &>/dev/null; then
        echo ""
        echo "fswatch not found -- install it with: brew install fswatch"
        echo "Running once without watch mode."
        exit 0
    fi
    echo ""
    echo "Watching main.swift for changes (Ctrl-C to stop)..."
    fswatch -o main.swift | while read -r _; do
        echo ""
        echo "-- File changed --"
        _kill
        _build && _run || echo "  x Build failed -- app not relaunched"
    done
fi
