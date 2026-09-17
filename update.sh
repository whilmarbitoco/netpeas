#!/usr/bin/env bash
set -Eeuo pipefail

REPO_URL="https://github.com/whilmarbitoco/netpeas.git"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
WRAPPER_NAME="${WRAPPER_NAME:-netpeas}"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED="\033[0;31m"; GREEN="\033[0;32m"; YELLOW="\033[1;33m"; NC="\033[0m"
log()  { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[-]${NC} $*"; }

# Check if installed via git
if [[ -d "$SOURCE_DIR/.git" ]]; then
    log "Updating from git..."
    cd "$SOURCE_DIR"
    git pull origin master 2>&1 | tail -3
    log "Update complete"
else
    # Re-install from scratch
    log "Not a git install. Re-downloading..."
    TEMP_DIR="$(mktemp -d)"
    git clone "$REPO_URL" "$TEMP_DIR/netpeas" 2>&1 | tail -3
    cp -r "$TEMP_DIR/netpeas/"* "$SOURCE_DIR/"
    rm -rf "$TEMP_DIR"
    log "Update complete"
fi

# Re-create wrapper
cat > "$INSTALL_DIR/$WRAPPER_NAME" << WRAPPER
#!/usr/bin/env bash
set -Eeuo pipefail
export NETPEAS_HOME="$SOURCE_DIR"
source "$SOURCE_DIR/netpeas" "\$@"
WRAPPER

chmod +x "$INSTALL_DIR/$WRAPPER_NAME"
log "Wrapper updated at $INSTALL_DIR/$WRAPPER_NAME"
