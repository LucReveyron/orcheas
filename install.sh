#!/usr/bin/env bash
# install.sh
# Installs orcheas globally. Does NOT touch ~/.claude.
#
# What it does:
#   1. Copies orcheas to ~/.local/share/orcheas
#   2. Adds an `orcheas` shell function to your shell rc file
#
# Usage: ./install.sh [--dry-run]

set -euo pipefail

INSTALL_DIR="$HOME/.local/share/orcheas"
DRY_RUN=false

[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

if [[ -f "$HOME/.zshrc" ]]; then
  RC_FILE="$HOME/.zshrc"
elif [[ -f "$HOME/.bashrc" ]]; then
  RC_FILE="$HOME/.bashrc"
else
  RC_FILE="$HOME/.profile"
fi

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { echo "  $*"; }
run() {
  if $DRY_RUN; then echo "  [dry-run] $*"
  else eval "$*"
  fi
}

[[ -d "$INSTALL_DIR" ]] && MODE="update" || MODE="install"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "orcheas $MODE"
$DRY_RUN && echo "(dry-run mode — no changes will be made)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── Step 1: Copy files ────────────────────────────────────────────────────────
echo ""
echo "▶ Installing to $INSTALL_DIR"
run "mkdir -p '$INSTALL_DIR'"
run "cp -r '$SOURCE_DIR/templates' '$INSTALL_DIR/'"
run "cp    '$SOURCE_DIR/orcheas'   '$INSTALL_DIR/'"
run "cp    '$SOURCE_DIR/CLAUDE.md' '$INSTALL_DIR/'"
run "chmod +x '$INSTALL_DIR/orcheas'"
run "echo '$SOURCE_DIR' > '$INSTALL_DIR/.source'"
log "done"

# ── Step 2: Shell function ────────────────────────────────────────────────────
echo ""
echo "▶ Adding shell function to $RC_FILE"

MARKER="# orcheas — Claude Code scaffolding"
SHELL_BLOCK="
$MARKER
orcheas() { bash \"\$HOME/.local/share/orcheas/orcheas\" \"\$@\"; }
"

if grep -qF "$MARKER" "$RC_FILE" 2>/dev/null; then
  log "already present in $RC_FILE — skipping"
else
  run "printf '%s\n' '$SHELL_BLOCK' >> '$RC_FILE'"
  log "done"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ $MODE complete."
echo ""
if [[ "$MODE" == "install" ]]; then
  echo "  source $RC_FILE"
  echo ""
  echo "Then in any project:"
fi
echo "  orcheas init  [path]     scaffold vault + CLAUDE.md"
echo "  orcheas clean <vault>    reset active/ and memories/"
echo "  orcheas update           pull latest from source repo"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
