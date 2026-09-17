#!/usr/bin/env bash
#
# NetPEAS — lib/utils.sh
# Shared utility functions.
#

[[ -n "${_NETPEAS_UTILS_LOADED:-}" ]] && return 0
readonly _NETPEAS_UTILS_LOADED=1


# ── Logging ──────────────────────────────────────────────────────────────────

peas_log_info()    { [[ "${VERBOSE:-0}" -ge 1 ]] && echo -e "${SYM_DEBUG} [INFO] $*" >&2 || true; }
peas_log_debug()   { [[ "${VERBOSE:-0}" -ge 2 ]] && echo -e "${SYM_DEBUG} [DEBUG] $*" >&2 || true; }
peas_log_warn()    { echo -e "${SYM_WARN} [WARN] $*" >&2; }
peas_log_error()   { echo -e "${SYM_ERROR} [ERROR] $*" >&2; }

# ── Target validation ─────────────────────────────────────────────────────────

# Validate IP address
peas_validate_ip() {
    local ip="$1"
    [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

# Validate CIDR
peas_validate_cidr() {
    local cidr="$1"
    [[ "$cidr" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$ ]]
}

# Validate hostname
peas_validate_host() {
    local host="$1"
    [[ "$host" =~ ^[a-zA-Z0-9._-]+$ ]]
}

# ── Temporary workspace ─────────────────────────────────────────────────────

peas_mktemp_dir() {
    local tmpdir
    tmpdir="$(mktemp -d -t netpeas.XXXXXX)"
    echo "$tmpdir"
}

peas_cleanup() {
    local dir="$1"
    [[ -n "$dir" && -d "$dir" ]] && rm -rf "$dir"
}

# ── Concurrency control ──────────────────────────────────────────────────────

# Wait for a job slot to free up (bounded parallelism)
peas_wait_slot() {
    local max_jobs="${1:-4}"
    while (( $(jobs -rp | wc -l) >= max_jobs )); do
        sleep 0.1
    done
}

# Wait for all background jobs and collect exit codes
peas_wait_all() {
    local failures=0
    while IFS= read -r line; do
        local pid exit_code
        pid="$(echo "$line" | cut -d: -f1)"
        exit_code="$(echo "$line" | cut -d: -f2)"
        if [[ "$exit_code" -ne 0 ]]; then
            ((failures++)) || true
        fi
    done < <(wait -n -p PID_RET 2>/dev/null || true)
    return "$failures"
}

# ── Timeout execution ────────────────────────────────────────────────────────

# Run a command with timeout, capture stdout/stderr/exit code
# Usage: peas_run_cmd <timeout_sec> <cmd...>
peas_run_cmd() {
    local timeout_sec="$1"; shift
    local stdout_file stderr_file
    stdout_file="$(mktemp)"
    stderr_file="$(mktemp)"
    local exit_code=0

    timeout --signal=KILL "${timeout_sec}" "$>" "$stdout_file" 2> "$stderr_file" || exit_code=$?

    # Output results
    echo "EXIT:$exit_code"
    echo "STDOUT:"
    cat "$stdout_file"
    echo "---"
    echo "STDERR:"
    cat "$stderr_file"

    rm -f "$stdout_file" "$stderr_file"
    return "$exit_code"
}

# ── Output helpers ────────────────────────────────────────────────────────────

# Truncate long strings
peas_truncate() {
    local str="$1"
    local max="${2:-80}"
    if [[ "${#str}" -gt "$max" ]]; then
        echo "${str:0:$((max-3))}..."
    else
        echo "$str"
    fi
}

# Extract first match from text using regex
peas_extract() {
    local text="$1"
    local pattern="$2"
    echo "$text" | grep -oP "$pattern" | head -1
}
