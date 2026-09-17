#!/usr/bin/env bash
#
# NetPEAS — lib/colors.sh
# Terminal color definitions and formatting helpers.
#

# Prevent double-source
[[ -n "${_NETPEAS_COLORS_LOADED:-}" ]] && return 0
readonly _NETPEAS_COLORS_LOADED=1


# ── Colors ────────────────────────────────────────────────────────────────────
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly DIM='\033[2m'
readonly NC='\033[0m'

# ── Symbols ───────────────────────────────────────────────────────────────────
readonly SYM_INFO="${BLUE}[+]${NC}"
readonly SYM_WARN="${YELLOW}[!]${NC}"
readonly SYM_ERROR="${RED}[-]${NC}"
readonly SYM_FINDING="${PURPLE}[*]${NC}"
readonly SYM_DEBUG="${DIM}[.]${NC}"

# ── Severity colors ────────────────────────────────────────────────────────────
readonly SEV_INFO="${BLUE}INFO${NC}"
readonly SEV_LOW="${GREEN}LOW${NC}"
readonly SEV_MED="${YELLOW}MEDIUM${NC}"
readonly SEV_HIGH="${RED}HIGH${NC}"
readonly SEV_CRIT="${RED}CRITICAL${NC}"

# ── Functions ─────────────────────────────────────────────────────────────────

peas_info()    { echo -e "${SYM_INFO} $*"; }
peas_warn()    { echo -e "${SYM_WARN} $*" >&2; }
peas_error()   { echo -e "${SYM_ERROR} $*" >&2; }
peas_debug()   { [[ "${VERBOSE:-0}" -ge 1 ]] && echo -e "${SYM_DEBUG} $*" >&2 || true; }

peas_finding() {
    local severity="$1"; shift
    local sev_colored
    case "${severity,,}" in
        info)     sev_colored="${SEV_INFO}" ;;
        low)      sev_colored="${SEV_LOW}" ;;
        medium)   sev_colored="${SEV_MED}" ;;
        high)     sev_colored="${SEV_HIGH}" ;;
        critical) sev_colored="${SEV_CRIT}" ;;
        *)        sev_colored="${severity}" ;;
    esac
    echo -e "${SYM_FINDING} ${sev_colored} $*"
}

peas_section()    { echo ""; echo -e "${CYAN}═══ $* ═══${NC}"; }
peas_subsection() { echo -e "  ${WHITE}$*${NC}"; }
peas_detail()     { echo -e "    ${DIM}$*${NC}"; }
peas_bullet()     { echo -e "    ${DIM}•${NC} $*"; }
