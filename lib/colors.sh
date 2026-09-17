#!/usr/bin/env bash
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly DIM='\033[2m'
readonly NC='\033[0m'

readonly SYM_INFO='\033[0;34m[+]\033[0m'
readonly SYM_WARN='\033[1;33m[!]\033[0m'
readonly SYM_ERROR='\033[0;31m[-]\033[0m'
readonly SYM_FINDING='\033[0;35m[*]\033[0m'
readonly SYM_DEBUG='\033[2m[.]\033[0m'

readonly SEV_INFO='\033[0;34mINFO\033[0m'
readonly SEV_LOW='\033[0;32mLOW\033[0m'
readonly SEV_MED='\033[1;33mMEDIUM\033[0m'
readonly SEV_HIGH='\033[0;31mHIGH\033[0m'
readonly SEV_CRIT='\033[0;31mCRITICAL\033[0m'

peas_suppress_output() {
    [[ "${OUTPUT_FORMAT:-text}" == "json" ]]
}

peas_info()    { if ! peas_suppress_output; then echo -e "${SYM_INFO} $*"; fi; }
peas_warn()    { echo -e "${SYM_WARN} $*" >&2; }
peas_section() { if ! peas_suppress_output; then echo ""; echo -e "${CYAN}═══ $* ═══${NC}"; fi; }
peas_subsection() { if ! peas_suppress_output; then echo -e "  ${WHITE}$*${NC}"; fi; }
peas_detail()  { if ! peas_suppress_output; then echo -e "    ${DIM}$*${NC}"; fi; }
peas_bullet()  { if ! peas_suppress_output; then echo -e "    ${DIM}•${NC} $*"; fi; }
peas_debug()   { if [[ $VERBOSE -ge 2 ]]; then echo -e "${SYM_DEBUG} $*" >&2; fi; }
