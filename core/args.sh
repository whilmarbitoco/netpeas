#!/usr/bin/env bash
#
# NetPEAS — core/args.sh
# Argument parsing and global configuration.
#

[[ -n "${_NETPEAS_ARGS_LOADED:-}" ]] && return 0
readonly _NETPEAS_ARGS_LOADED=1

set -Eeuo pipefail

# ── Global state ──────────────────────────────────────────────────────────────

TARGETS=()
MODE="normal"          # fast, normal, aggressive
VERBOSE=0
OUTPUT_FORMAT="text"   # text, json
TIMEOUT=5
MAX_PARALLEL=4
STATE_DIR=""

# ── Parse arguments ───────────────────────────────────────────────────────────

peas_parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --fast)
                MODE="fast"
                MAX_PARALLEL=8
                shift
                ;;
            --aggressive)
                MODE="aggressive"
                MAX_PARALLEL=6
                TIMEOUT=10
                shift
                ;;
            --verbose|-v)
                VERBOSE=1
                shift
                ;;
            --debug)
                VERBOSE=2
                shift
                ;;
            --json)
                OUTPUT_FORMAT="json"
                shift
                ;;
            --timeout)
                shift
                TIMEOUT="${1:-5}"
                shift
                ;;
            --parallel)
                shift
                MAX_PARALLEL="${1:-4}"
                shift
                ;;
            --state-dir)
                shift
                STATE_DIR="$1"
                shift
                ;;
            --help|-h)
                peas_show_help
                exit 0
                ;;
            -*)
                peas_error "Unknown option: $1"
                peas_show_help
                exit 2
                ;;
            *)
                TARGETS+=("$1")
                shift
                ;;
        esac
    done

    # Validate
    if [[ ${#TARGETS[@]} -eq 0 ]]; then
        peas_error "No target specified"
        peas_show_help
        exit 2
    fi
}

# ── Show help ─────────────────────────────────────────────────────────────────

peas_show_help() {
    cat << 'HELP'
NetPEAS — Network Enumeration & Vulnerability Triage

Usage:
  netpeas [options] <target>

Target:
  IP address, CIDR, or hostname

Options:
  --fast           Fast scan (skip deep enum, max parallelism)
  --aggressive     Deep enumeration with longer timeouts
  --verbose, -v    Show detailed output
  --debug          Show debug output (very verbose)
  --json           Output as JSON
  --timeout SEC    Timeout per command (default: 5)
  --parallel N     Max parallel workers (default: 4)
  --state-dir DIR  Directory for scan state
  --help, -h       Show this help

Examples:
  netpeas 10.10.10.24
  netpeas --fast 192.168.1.0/24
  netpeas --json --aggressive target.local

HELP
}

# ── Getters ───────────────────────────────────────────────────────────────────

peas_get_mode()            { echo "$MODE"; }
peas_get_timeout()         { echo "$TIMEOUT"; }
peas_get_parallel()        { echo "$MAX_PARALLEL"; }
peas_get_output_format()   { echo "$OUTPUT_FORMAT"; }
