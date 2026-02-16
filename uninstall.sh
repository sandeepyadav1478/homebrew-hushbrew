#!/bin/bash
#
# Uninstall hushbrew
#
# Unloads the LaunchAgent and removes all installed files.
#

set -euo pipefail

LABEL="com.local.hushbrew"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

echo "Uninstalling hushbrew..."

# ── Unload LaunchAgent ──

if launchctl print "gui/$(id -u)/$LABEL" &>/dev/null; then
    launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
    echo "  Unloaded LaunchAgent"
else
    echo "  LaunchAgent was not loaded"
fi

# ── Remove files ──

rm -f "$PLIST"
echo "  Removed $PLIST"

rm -f "$HOME/.local/bin/hushbrew.sh"
rm -f "$HOME/.local/bin/brew-curl"
echo "  Removed scripts from ~/.local/bin/"

rm -f "$HOME/.local/log/hushbrew.log"
rm -f "$HOME/.local/log/hushbrew.log.old"
rm -f "$HOME/.local/log/hushbrew.lastrun"
echo "  Removed log and state files"

rmdir "$HOME/.local/log" 2>/dev/null || true
rmdir "$HOME/.local/bin" 2>/dev/null || true

# ── Config ──

if [ -d "$HOME/.config/hushbrew" ]; then
    echo ""
    echo "  Note: Config kept at ~/.config/hushbrew/"
    echo "  Remove it manually if you no longer need it:"
    echo "    rm -rf ~/.config/hushbrew"
fi

# ── Lock file ──

rmdir /tmp/hushbrew.lock 2>/dev/null || true

echo ""
echo "Done! hushbrew has been uninstalled."
