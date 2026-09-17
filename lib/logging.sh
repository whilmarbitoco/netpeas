#!/usr/bin/env bash

LOG_FILE=""
LOG_PEAS_DEBUG=0

peas_log_init() {
    LOG_FILE="${1:-/tmp/netpeas_$(date +%s).log}"
    LOG_PEAS_DEBUG="${2:-0}"
    echo "=== NetPEAS Log $(date -u +%Y-%m-%dT%H:%M:%SZ) ===" > "$LOG_FILE"
}

peas_log_write() {
    local level="$1" message="$2"
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    echo "[${timestamp}] [${level}] ${message}" >> "$LOG_FILE" 2>/dev/null
}

peas_log_info()    { peas_log_write "INFO" "$1"; }
peas_log_warn()    { peas_log_write "WARN" "$1"; }
peas_log_error()   { peas_log_write "ERROR" "$1"; }
peas_log_debug()   { [[ $LOG_PEAS_DEBUG -ge 1 ]] && peas_log_write "DEBUG" "$1"; }

LAST_REQUEST_TIME=0
MIN_REQUEST_INTERVAL=0.1

peas_rate_limit() {
    local now=$(date +%s%N 2>/dev/null || echo "$(date +%s)000000000")
    local diff=$(( (now - LAST_REQUEST_TIME) / 1000000 ))
    if [[ $diff -lt $(echo "$MIN_REQUEST_INTERVAL" | awk '{print $1 * 1000}') ]]; then
        sleep "$MIN_REQUEST_INTERVAL"
    fi
    LAST_REQUEST_TIME=$now
}
