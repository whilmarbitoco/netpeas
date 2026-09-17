#!/usr/bin/env bash

declare -A MODULE_MAP=(
    [http]=http [https]=https [ssh]=ssh [ftp]=ftp [smb]=smb
    [dns]=dns [smtp]=smtp [ldap]=ldap [snmp]=snmp [mysql]=mysql
    [postgres]=postgres [postgresql]=postgres [redis]=redis
)

peas_schedule_modules() {
    local services_file="$1"
    local state_dir="$2"

    [[ ! -s "$services_file" ]] && { peas_warn "No services to enumerate"; return 1; }

    peas_section "Service Enumeration"

    local total=0 completed=0 skipped=0

    while IFS='|' read -r host port protocol service product version; do
        [[ -z "$port" || "$port" == "0" ]] && continue
        total=$((total + 1))
        local module="${MODULE_MAP[$service]:-}"
        [[ -z "$module" ]] && { skipped=$((skipped + 1)); continue; }
        local module_file="${SCRIPT_DIR}/modules/${module}.sh"
        [[ ! -f "$module_file" ]] && { skipped=$((skipped + 1)); continue; }

        local entry="${module}_module"
        source "$module_file" 2>/dev/null || { skipped=$((skipped + 1)); continue; }
        if declare -f "$entry" >/dev/null 2>&1; then
            "$entry" "$host" "$port" "$state_dir" 2>/dev/null && completed=$((completed + 1)) || {
                peas_warn "$module module failed for $host:$port"
            }
        else
            skipped=$((skipped + 1))
        fi
    done < "$services_file"

    peas_debug "Scheduled: $total, Completed: $completed, Skipped: $skipped" || true
    return 0
}
