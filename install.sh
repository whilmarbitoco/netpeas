#!/usr/bin/env bash
set -Eeuo pipefail

INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
INSTALL_NAME="${INSTALL_NAME:-netpeas}"
WRAPPER_NAME="${WRAPPER_NAME:-netpeas}"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED="\033[0;31m"; GREEN="\033[0;32m"; YELLOW="\033[1;33m"; NC="\033[0m"
log()  { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[-]${NC} $*"; }

# Check if running as root for system-wide install
if [[ "$INSTALL_DIR" == "/usr/local/bin" || "$INSTALL_DIR" == "/usr/bin" ]]; then
    if [[ $EUID -ne 0 ]]; then
        warn "System-wide install requires root. Trying user-local..."
        INSTALL_DIR="$HOME/.local/bin"
    fi
fi

# Create install dir if it doesn't exist
mkdir -p "$INSTALL_DIR"

# Create wrapper script that sources the source dir
cat > "$INSTALL_DIR/$WRAPPER_NAME" << WRAPPER
#!/usr/bin/env bash
set -Eeuo pipefail
export NETPEAS_HOME="$SOURCE_DIR"
source "$SOURCE_DIR/netpeas" "\$@"
WRAPPER

chmod +x "$INSTALL_DIR/$WRAPPER_NAME"

# Verify
if command -v "$WRAPPER_NAME" &>/dev/null; then
    log "Installed $WRAPPER_NAME to $INSTALL_DIR/$WRAPPER_NAME"
    log "Version: $($WRAPPER_NAME --help 2>&1 | head -1)"
    log "Run '$WRAPPER_NAME <target>' to start scanning"
else
    # Add to PATH if needed
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        warn "$INSTALL_DIR is not in your PATH"
        warn "Add this to your shell profile:"
        warn "  export PATH=\$PATH:$INSTALL_DIR"
    fi
    log "Installed $WRAPPER_NAME to $INSTALL_DIR/$WRAPPER_NAME"
    log "Run '$INSTALL_DIR/$WRAPPER_NAME <target>' to start scanning"
fi
