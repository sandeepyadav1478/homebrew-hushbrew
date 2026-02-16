#!/bin/bash
#
# Install hushbrew
#
# Copies scripts, generates the LaunchAgent plist, creates default config,
# and loads the agent so upgrades start running on schedule.
#

set -euo pipefail

# ── Preflight checks ──

if [[ "$(uname)" != "Darwin" ]]; then
    echo "Error: hushbrew only works on macOS." >&2
    exit 1
fi

if ! command -v brew &>/dev/null; then
    echo "Error: Homebrew is not installed." >&2
    echo "Install it from https://brew.sh" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LABEL="com.local.hushbrew"

# ── Target directories ──

BIN_DIR="$HOME/.local/bin"
LOG_DIR="$HOME/.local/log"
CONFIG_DIR="$HOME/.config/hushbrew"
PLIST_DIR="$HOME/Library/LaunchAgents"

echo "Installing hushbrew..."

# ── Create directories ──

mkdir -p "$BIN_DIR" "$LOG_DIR" "$CONFIG_DIR" "$PLIST_DIR"

# ── Copy scripts ──

cp "$SCRIPT_DIR/bin/hushbrew.sh" "$BIN_DIR/hushbrew.sh"
cp "$SCRIPT_DIR/bin/brew-curl" "$BIN_DIR/brew-curl"
chmod +x "$BIN_DIR/hushbrew.sh" "$BIN_DIR/brew-curl"

echo "  Installed scripts to $BIN_DIR"

# ── Create default config (if not already present) ──

if [ ! -f "$CONFIG_DIR/config" ]; then
    cat > "$CONFIG_DIR/config" << 'EOF'
# hushbrew configuration
#
# Exclusion lists — space-separated package names that should NOT be auto-upgraded.
# Example: EXCLUDED_FORMULAE="node python@3.11"

EXCLUDED_FORMULAE=""
EXCLUDED_CASKS=""
EOF
    echo "  Created default config at $CONFIG_DIR/config"
else
    echo "  Config already exists at $CONFIG_DIR/config (kept)"
fi

# ── Generate plist from template ──

sed "s|__HOME__|$HOME|g" "$SCRIPT_DIR/launchd/com.local.hushbrew.plist" \
    > "$PLIST_DIR/$LABEL.plist"

echo "  Installed LaunchAgent plist"

# ── Load LaunchAgent ──

# Unload first if already loaded (ignore errors)
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true

launchctl bootstrap "gui/$(id -u)" "$PLIST_DIR/$LABEL.plist"

echo "  Loaded LaunchAgent"

echo ""
echo "Done! hushbrew is now installed and scheduled."
echo ""
echo "Schedule: 10:00 AM, 2:00 PM, 6:00 PM daily (skips if already updated)"
echo "Config:   $CONFIG_DIR/config"
echo "Logs:     $LOG_DIR/hushbrew.log"
echo ""
echo "To run manually:  $BIN_DIR/hushbrew.sh"
echo "To uninstall:     $SCRIPT_DIR/uninstall.sh"
