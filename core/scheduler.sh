#!/usr/bin/env bash
#
# NetPEAS — core/scheduler.sh
# Service-to-module mapping and parallel dispatch.
#

[[ -n "${_NETPEAS_SCHEDULER_LOADED:-}" ]] && return 0
readonly _NETPEAS_SCHEDULER_LOADED=1

set -Eeuo pipefail

# ── Module registry ─────────────────────────────────────────────────────────

# Maps service names to module files
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

# ── Schedule modules for discovered services ─────────────────────────────────

peas_schedule_modules() {
    local services_file="$1"
    local state_dir="$2"

    if [[ ! -f "$services_file" ]]; then
        peas_warn "No services file found"
        return 1
    fi

    peas_section "Service Enumeration"

    local total=0 completed=0 skipped=0

    while IFS='|' read -r host port protocol service product version; do
        [[ -z "$port" || "$port" == "unknown" ]] && continue
        ((total++))

        local module="${MODULE_MAP[$service]:-}"

        if [[ -z "$module" ]]; then
            peas_debug "No module for service: $service ($host:$port)"
            ((skipped++))
            continue
        fi

        peas_dispatch_module "$module" "$host" "$port" "$state_dir" &
        ((completed++))

        # Bounded parallelism
        peas_wait_slot "$(peas_get_parallel)"

    done < "$services_file"

    peas_debug "Scheduled: $total, Dispatched: $completed, Skipped: $skipped"

    # Wait for all background jobs
    wait 2>/dev/null || true
}

# ── Dispatch a module ────────────────────────────────────────────────────────

peas_dispatch_module() {
    local module="$1"
    local host="$2"
    local port="$3"
    local state_dir="$4"

    local module_file="/workspace/netpeas/modules/${module}.sh"

    if [[ ! -f "$module_file" ]]; then
        peas_warn "Module file not found: $module.sh"
        return 1
    fi

    # Source module and call its entry function
    source "$module_file"

    local module_func="${module}_module"

    if declare -f "$module_func" > /dev/null 2>&1; then
        peas_info "Running $module module against $host:$port"
        "$module_func" "$host" "$port" "$state_dir" || {
            peas_warn "$module module failed for $host:$port"
        }
    else
        peas_warn "Module function not found: $module_func"
    fi
}

