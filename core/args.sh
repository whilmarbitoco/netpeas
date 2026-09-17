#!/usr/bin/env bash



TARGETS=()
MODE="normal"
VERBOSE=0
OUTPUT_FORMAT="text"
TIMEOUT=300
MAX_PARALLEL=4
STATE_DIR=""
MIN_SEVERITY="INFO"
SERVICE_FILTER=""
MODULE_FILTER=""
TARGETS_FILE=""
RESUME=false
LOG_FILE=""
FINDINGS_ONLY=false
NO_INTEL=false

peas_usage() {
    cat << 'USAGE'
NetPEAS — Network Enumeration & Vulnerability Triage

Usage: netpeas [OPTIONS] <target> [target2 ...]

Targets:
  IP address, CIDR (10.0.0.0/24), hostname, or range (10.0.0.1-254)

Modes:
  -f, --fast            Fast scan (top ports, max parallelism)
  -a, --aggressive      Deep enumeration with longer timeouts
  -j, --json            JSON output

Filtering:
  --min-severity LEVEL  Minimum severity (INFO|LOW|MEDIUM|HIGH|CRITICAL)
  --service LIST        Comma-separated service filter (http,ssh,smb)
  --module LIST         Comma-separated module filter (http,ssh,smb)

Options:
  -t, --timeout SECS    Timeout per command (default: 300)
  -p, --parallel N      Parallel workers (default: 4)
  -s, --state-dir DIR   State directory
  --targets-file FILE   File with targets (one per line)
  --resume              Resume interrupted scan
  --log-file PATH       Debug log file
  --findings-only       Suppress enumeration output
  --no-intel            Skip SearchSploit/CVE lookup
  --verbose, -v         Verbose output
  --debug               Debug output
  -h, --help            Show help
  --version             Show version

Examples:
  netpeas 10.10.10.24
  netpeas --fast --json 10.10.10.24
  netpeas --min-severity HIGH --service http,ssh 10.10.10.24
USAGE
}

peas_parse_args() {
    # Reset all variables to defaults
    TARGETS=()
    MODE="normal"
    VERBOSE=0
    OUTPUT_FORMAT="text"
    TIMEOUT=300
    MAX_PARALLEL=4
    STATE_DIR=""
    MIN_SEVERITY="INFO"
    SERVICE_FILTER=""
    MODULE_FILTER=""
    TARGETS_FILE=""
    RESUME=false
    LOG_FILE=""
    FINDINGS_ONLY=false
    NO_INTEL=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                peas_usage
                return 2
                ;;
            --version)
                echo "NetPEAS v1.0"
                return 2
                ;;
            -f|--fast)
                MODE="fast"
                MAX_PARALLEL=8
                shift
                ;;
            -a|--aggressive)
                MODE="aggressive"
                MAX_PARALLEL=6
                TIMEOUT=600
                shift
                ;;
            -v|--verbose)
                VERBOSE=1
                shift
                ;;
            --debug)
                VERBOSE=2
                shift
                ;;
            -j|--json)
                OUTPUT_FORMAT="json"
                shift
                ;;
            --timeout|-t)
                shift
                TIMEOUT="${1:-300}"
                shift
                ;;
            --parallel|-p)
                shift
                MAX_PARALLEL="${1:-4}"
                shift
                ;;
            --state-dir|-s)
                shift
                STATE_DIR="$1"
                shift
                ;;
            --min-severity)
                shift
                MIN_SEVERITY="${1:-INFO}"
                shift
                ;;
            --service)
                shift
                SERVICE_FILTER="$1"
                shift
                ;;
            --module)
                shift
                MODULE_FILTER="$1"
                shift
                ;;
            --targets-file)
                shift
                TARGETS_FILE="$1"
                shift
                ;;
            --resume)
                RESUME=true
                shift
                ;;
            --log-file)
                shift
                LOG_FILE="$1"
                shift
                ;;
            --findings-only)
                FINDINGS_ONLY=true
                shift
                ;;
            --no-intel)
                NO_INTEL=true
                shift
                ;;
            --*)
                peas_error "Unknown option: $1"
                peas_usage
                return 3
                ;;
            *)
                TARGETS+=("$1")
                shift
                ;;
        esac
    done

    if [[ -n "$TARGETS_FILE" ]]; then
        if [[ -f "$TARGETS_FILE" ]]; then
            while IFS= read -r line; do
                [[ -z "$line" || "$line" =~ ^# ]] && continue
                TARGETS+=("$line")
            done < "$TARGETS_FILE"
        else
            peas_error "Targets file not found: $TARGETS_FILE"
            return 4
        fi
    fi

    if [[ ${#TARGETS[@]} -eq 0 ]]; then
        peas_error "No target specified"
        peas_usage
        return 2
    fi
}

peas_get_mode()            { echo "$MODE"; }
peas_get_timeout()         { echo "$TIMEOUT"; }
peas_get_parallel()        { echo "$MAX_PARALLEL"; }
peas_get_output_format()   { echo "$OUTPUT_FORMAT"; }
