#!/usr/bin/env bash
set -Eeuo pipefail

INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
WRAPPER_NAME="${WRAPPER_NAME:-netpeas}"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED="\033[0;31m"; GREEN="\033[0;32m"; YELLOW="\033[1;33m"; NC="\033[0m"
log()  { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[-]${NC} $*"; }

# Remove wrapper
if [[ -f "$INSTALL_DIR/$WRAPPER_NAME" ]]; then
    rm -f "$INSTALL_DIR/$WRAPPER_NAME"
    log "Removed $INSTALL_DIR/$WRAPPER_NAME"
else
    warn "Wrapper not found at $INSTALL_DIR/$WRAPPER_NAME"
fi

# Ask about source directory
read -p "Remove source directory ($SOURCE_DIR)? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "$SOURCE_DIR"
    log "Removed $SOURCE_DIR"
fi

log "Uninstall complete"
