#!/usr/bin/env bash
#
# NetPEAS — modules/snmp.sh
# SNMP service enumeration.
#

[[ -n "${_NETPEAS_MODULE_SNMP_LOADED:-}" ]] && return 0
readonly _NETPEAS_MODULE_SNMP_LOADED=1

set -Eeuo pipefail

snmp_module() {
    local host="$1"
    local port="$2"
    local state_dir="$3"

    local output_file="${state_dir}/snmp_${host}_${port}.txt"
    : > "$output_file"

    peas_info "SNMP — $host:$port"

    if ! peas_has_tool snmpwalk; then
        peas_warn "snmpwalk not available; skipping SNMP"
        return 1
    fi

    # Default community strings
    for community in public private; do
        local result
        result="$(peas_exec_silent 10 snmpwalk -v1 -c "$community" "$host" system 2>/dev/null || echo "")"
        if [[ -n "$result" ]]; then
            echo "$result" > "$output_file"
            peas_finding "medium" "SNMP community string: $community"
            peas_add_finding "$host" "$port" "snmp" "auth" "high" "confirmed" \
                "Weak SNMP community" "Community '$community' accepted" "snmpwalk" \
                "Change default community strings"
            break
        fi
    done
}

