#!/usr/bin/env bash
[[ -n "${_NETPEAS_MODULE_SNMP_LOADED:-}" ]] && return 0
readonly _NETPEAS_MODULE_SNMP_LOADED=1

snmp_module() {
    local host="$1"
    local port="$2"
    local state_dir="$3"

    local output_file="${state_dir}/snmp_${host}_${port}.txt"
    : > "$output_file"

    peas_info "SNMP — $host:$port"

    # ── Multiple Community Strings ───────────────────────────────────────────
    local communities="public private admin guest system"
    local found_community=""

    if peas_has_tool snmpwalk; then
        for comm in $communities; do
            local walk_result
            walk_result="$(peas_exec_silent 10 snmpwalk -v2c -c "$comm" "$host":"$port" system 2>/dev/null || echo "")"
            if [[ -n "$walk_result" ]] && ! echo "$walk_result" | grep -qi "timeout\|error"; then
                found_community="$comm"
                echo "$walk_result" > "$output_file"

                peas_add_finding "$host" "$port" "snmp" "community" "high" confirmed                     "Default community string: $comm" "Access granted with community: $comm" "snmpwalk"                     "Change default community strings"

                # System info extraction
                local sysdescr="$(echo "$walk_result" | grep 'sysDescr' | head -1)"
                local sysname="$(echo "$walk_result" | grep 'sysName' | head -1)"
                [[ -n "$sysdescr" ]] && peas_detail "$sysdescr"
                [[ -n "$sysname" ]] && peas_detail "$sysname"

                # Interface enumeration
                local ifcount="$(peas_exec_silent 10 snmpwalk -v2c -c "$comm" "$host":"$port" IF-MIB::ifDescr 2>/dev/null | wc -l)"
                [[ $ifcount -gt 0 ]] && peas_add_finding "$host" "$port" "snmp" "enum" "medium" observed                     "SNMP interface enumeration" "$ifcount interfaces found" "snmpwalk"                     "Restrict SNMP access"

                break
            fi
        done

        if [[ -z "$found_community" ]]; then
            peas_add_finding "$host" "$port" "snmp" "info" "info" observed                 "SNMP service detected" "Port $port/udp" "port"                 "Verify community strings are strong"
        fi
    fi

    peas_add_finding "$host" "$port" "snmp" "info" "info" observed         "SNMP Service" "Port $port/udp" "port" "Ensure SNMPv3 is used"
}
