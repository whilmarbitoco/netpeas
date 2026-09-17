#!/usr/bin/env bash
#
# NetPEAS — core/executor.sh
# Safe command execution with timeout, logging, and error handling.
#



# ── Execute with timeout ─────────────────────────────────────────────────────

peas_exec() {
    local timeout_sec="$1"
    shift
    local cmd=("$@")
    local stdout_file stderr_file exit_code

    stdout_file="$(mktemp)"
    stderr_file="$(mktemp)"

    peas_debug "Executing: ${cmd[*]}"

    exit_code=0
    timeout --signal=KILL "$timeout_sec" "${cmd[@]}" > "$stdout_file" 2> "$stderr_file" || exit_code=$?

    # Output results
    cat "$stdout_file"
    [[ -s "$stderr_file" ]] && cat "$stderr_file" >&2

    rm -f "$stdout_file" "$stderr_file"
    return "$exit_code"
}

# ── Execute silently (capture only, no output on failure) ─────────────────────

peas_exec_silent() {
    local timeout_sec="$1"
    shift
    local cmd=("$@")
    local stdout_file stderr_file exit_code

    stdout_file="$(mktemp)"
    stderr_file="$(mktemp)"

    exit_code=0
    timeout --signal=KILL "$timeout_sec" "${cmd[@]}" > "$stdout_file" 2> "$stderr_file" || exit_code=$?

    cat "$stdout_file"
    rm -f "$stdout_file" "$stderr_file"
    return "$exit_code"
}
