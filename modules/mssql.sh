#!/usr/bin/env bash
#
# NetPEAS — modules/mssql.sh
# Microsoft SQL Server enumeration
#

mssql_module() {
    local host="$1"
    local port="$2"
    local state_dir="$3"

    local output_file="${state_dir}/mssql_${host}_${port}.txt"
    : > "$output_file"

    peas_info "MSSQL — $host:$port"

    # ── Banner Grab ────────────────────────────────────────────────────
    if peas_has_tool nc; then
        local banner
        banner="$(peas_exec_silent 5 bash -c "echo -ne '\x12\x01\x00\x34\x00\x00\x00\x00\x00\x00\x15\x00\x06\x01\x00\x1b\x00\x01\x02\x00\x1c\x00\x0c\x03\x00\x28\x00\x04\xff\x08\x00\x01\x55\x00\x00\x00\x4d\x53\x53\x51\x4c\x53\x65\x72\x76\x65\x72\x00\x48\x0f\x00\x00' | timeout 5 nc -w3 $host $port 2>/dev/null | xxd | head -5")"
        echo "$banner" > "$output_file"
    fi

    # ── Nmap MSSQL Scripts ─────────────────────────────────────────────
    if peas_has_tool nmap; then
        local mssql_info
        mssql_info="$(peas_exec_silent 20 nmap -p "$port" --script=mssql-info,mssql-enum "$host" 2>/dev/null || echo "")"
        if [[ -n "$mssql_info" ]]; then
            echo "$mssql_info" >> "$output_file"

            local version="$(echo "$mssql_info" | grep -oP 'Version:.*' | head -1)"
            local instance="$(echo "$mssql_info" | grep -oP 'Instance:.*' | head -1)"
            [[ -n "$version" ]] && peas_detail "$version"
            [[ -n "$instance" ]] && peas_detail "$instance"

            peas_add_finding "$host" "$port" "mssql" "info" "medium" "confirmed" \
                "MSSQL server detected" "Version: ${version:-unknown}" "nmap" \
                "Verify SQL Server authentication configuration"
        fi
    fi

    # ── SA Account Check ───────────────────────────────────────────────
    if peas_has_tool impacket; then
        local sa_check
        sa_check="$(peas_exec_silent 15 python3 -c "
try:
    from impacket.tds import MSSQL
    conn = MSSQL('$host', $port)
    conn.connect()
    print('MSSQL connection successful')
    conn.disconnect()
except Exception as e:
    print(f'SA check: {e}')
" 2>/dev/null || echo "")"
        if [[ -n "$sa_check" ]]; then
            echo "$sa_check" >> "$output_file"
            if echo "$sa_check" | grep -qi "successful\|connected"; then
                peas_add_finding "$host" "$port" "mssql" "auth" "critical" "observed" \
                    "MSSQL connection possible" "Check if SA account has blank password" "impacket" \
                    "Disable SA account or enforce strong password"
            fi
        fi
    fi

    # ── xp_cmdshell Check ──────────────────────────────────────────────
    if peas_has_tool nmap; then
        local xp_cmdshell
        xp_cmdshell="$(peas_exec_silent 15 nmap -p "$port" --script=mssql-xp-cmdshell "$host" 2>/dev/null || echo "")"
        if [[ -n "$xp_cmdshell" ]] && echo "$xp_cmdshell" | grep -qi "enabled"; then
            peas_add_finding "$host" "$port" "mssql" "config" "critical" "confirmed" \
                "xp_cmdshell enabled" "Extended stored procedure allows OS command execution" "nmap" \
                "Disable xp_cmdshell if not needed"
        fi
    fi

    # ── Intelligence ────────────────────────────────────────────────────
    local exploit_results
    exploit_results="$(peas_searchsploit "Microsoft SQL Server" 5 2>/dev/null || echo "")"
    if [[ -n "$exploit_results" ]]; then
        echo "$exploit_results" >> "$output_file"
        peas_add_finding "$host" "$port" "mssql" "cve" "medium" "likely" \
            "Known MSSQL exploits" "$exploit_results" "searchsploit" \
            "Review and patch"
    fi

    return 0
}