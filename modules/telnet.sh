#!/usr/bin/env bash
#
# NetPEAS — modules/telnet.sh
# Telnet service enumeration
#

telnet_module() {
    local host="$1"
    local port="$2"
    local state_dir="$3"

    local output_file="${state_dir}/telnet_${host}_${port}.txt"
    : > "$output_file"

    peas_info "Telnet — $host:$port"

    # ── Banner Grab ────────────────────────────────────────────────────
    local banner=""
    if peas_has_tool nc; then
        banner="$(peas_exec_silent 5 bash -c "echo | timeout 5 nc -w3 $host $port 2>/dev/null | head -5")"
        echo "$banner" > "$output_file"
    fi

    # ── Cleartext Protocol Alert ───────────────────────────────────────
    peas_add_finding "$host" "$port" "telnet" "protocol" "high" "confirmed" \
        "Telnet cleartext protocol" "Telnet transmits data unencrypted" "nc" \
        "Replace Telnet with SSH immediately"

    # ── Authentication Check ───────────────────────────────────────────
    if [[ -n "$banner" ]]; then
        local banner_lower="$(echo "$banner" | tr '[:upper:]' '[:lower:]')"

        # Check for login prompt
        if echo "$banner_lower" | grep -qi "login:\|username:\|password:"; then
            peas_add_finding "$host" "$port" "telnet" "auth" "high" "observed" \
                "Telnet login prompt exposed" "Remote login without encryption" "nc" \
                "Disable Telnet, use SSH"
        fi

        # Check for Cisco IOS
        if echo "$banner_lower" | grep -qi "cisco\|ios"; then
            peas_add_finding "$host" "$port" "telnet" "type" "medium" "observed" \
                "Cisco device via Telnet" "Network device management unencrypted" "nc" \
                "Use SSH for network device management"
        fi

        # Check for embedded/IoT device
        if echo "$banner_lower" | grep -qi "busybox\|linux\|embedded\|router\|camera"; then
            peas_add_finding "$host" "$port" "telnet" "type" "medium" "observed" \
                "Embedded/IoT device via Telnet" "Unencrypted device management" "nc" \
                "Enable encrypted management, change defaults"
        fi
    fi

    # ── Intelligence ────────────────────────────────────────────────────
    local exploit_results
    exploit_results="$(peas_searchsploit "Telnet" 3 2>/dev/null || echo "")"
    if [[ -n "$exploit_results" ]]; then
        echo "$exploit_results" >> "$output_file"
    fi

    return 0
}