#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://raw.githubusercontent.com/agustif/ralph-opencode-template/main"
RALPH_SH="ralph.sh"

INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
[[ -d "$INSTALL_DIR" ]] || mkdir -p "$INSTALL_DIR"

echo "Installing ralph to $INSTALL_DIR..."

if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$REPO_URL/$RALPH_SH" -o "$INSTALL_DIR/$RALPH_SH"
elif command -v wget >/dev/null 2>&1; then
    wget -q "$REPO_URL/$RALPH_SH" -O "$INSTALL_DIR/$RALPH_SH"
else
    echo "Error: curl or wget required" >&2
    exit 1
fi

chmod +x "$INSTALL_DIR/$RALPH_SH"

# Create symlink without .sh extension for easier usage
ln -sf "$INSTALL_DIR/$RALPH_SH" "$INSTALL_DIR/ralph"

echo "Installed to: $INSTALL_DIR/ralph"
echo ""
echo "Usage: ralph [args...]"

if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo ""
    echo "⚠ Add $INSTALL_DIR to your PATH:"
    echo "  export PATH=\"\$PATH:$INSTALL_DIR\""
    echo "  Add this to your ~/.bashrc or ~/.zshrc"
fi

echo "✓ Installation complete"
