#!/usr/bin/env bash
#
# NetPEAS — core/scheduler.sh
# Service-to-module mapping and parallel dispatch.
#

[[ -n "${_NETPEAS_SCHEDULER_LOADED:-}" ]] && return 0
readonly _NETPEAS_SCHEDULER_LOADED=1


# ── Module registry ─────────────────────────────────────────────────────────

declare -A MODULE_MAP=(
    [http]=http
    [https]=https
    [ssh]=ssh
    [ftp]=ftp
    [smb]=smb
    [dns]=dns
    [smtp]=smtp
    [ldap]=ldap
    [snmp]=snmp
    [mysql]=mysql
    [postgres]=postgres
    [postgresql]=postgres
    [redis]=redis
)

# ── Schedule and run modules ───────────────────────────────────────────────

peas_schedule_modules() {
    local services_file="$1"
    local state_dir="$2"

    if [[ ! -s "$services_file" ]]; then
        peas_warn "No services to enumerate"
        return 1
    fi

    peas_section "Service Enumeration"

    local -a pids=()
    local total=0 completed=0 skipped=0

    while IFS='|' read -r host port protocol service product version; do
        [[ -z "$port" || "$port" == "0" ]] && continue
        ((total++))

        local module="${MODULE_MAP[$service]:-}"

        if [[ -z "$module" ]]; then
            peas_debug "No module: $service ($host:$port)"
            ((skipped++))
            continue
        fi

        local module_file="${SCRIPT_DIR}/modules/${module}.sh"
        [[ ! -f "$module_file" ]] && { ((skipped++)); continue; }

        # Run module in background
        (
            source "$module_file"
            local entry="${module}_module"
            if declare -f "$entry" >/dev/null 2>&1; then
                "$entry" "$host" "$port" "$state_dir" 2>/dev/null
            fi
        ) &
        pids+=($!)

        ((completed++))
        peas_wait_slot "$(peas_get_parallel)"

    done < "$services_file"

    peas_debug "Scheduled: $total, Running: $completed, Skipped: $skipped"

    # Wait for all
    local failures=0
    for pid in "${pids[@]}"; do
        wait "$pid" 2>/dev/null || ((failures++)) || true
    done

    [[ $failures -gt 0 ]] && peas_warn "$failures module(s) failed"
}
