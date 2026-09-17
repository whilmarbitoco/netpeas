#!/usr/bin/env bash
#
# NetPEAS — modules/vnc.sh
# VNC service enumeration
#

vnc_module() {
    local host="$1"
    local port="$2"
    local state_dir="$3"

    local output_file="${state_dir}/vnc_${host}_${port}.txt"
    : > "$output_file"

    peas_info "VNC — $host:$port"

    # ── Banner Grab ────────────────────────────────────────────────────
    local banner=""
    if peas_has_tool nc; then
        banner="$(peas_exec_silent 5 bash -c "echo | timeout 5 nc -w3 $host $port 2>/dev/null | head -3")"
        echo "$banner" > "$output_file"
    fi

    if [[ -n "$banner" ]]; then
        local version="$(echo "$banner" | grep -oP 'RFB \K[0-9.]+' | head -1)"
        peas_add_finding "$host" "$port" "vnc" "info" "medium" "observed" \
            "VNC service detected" "Version: ${version:-unknown}" "nc" \
            "Verify VNC authentication is configured"

        # Check for old VNC versions
        if [[ -n "$version" ]]; then
            local major="$(echo "$version" | cut -d. -f1)"
            local minor="$(echo "$version" | cut -d. -f2)"
            if [[ "$major" -lt 3 ]] || [[ "$major" -eq 3 && "$minor" -lt 8 ]]; then
                peas_add_finding "$host" "$port" "vnc" "version" "high" "observed" \
                    "Outdated VNC version" "Version $version may have known vulnerabilities" "nc" \
                    "Update VNC to latest version"
            fi
        fi
    fi

    # ── Authentication Check ───────────────────────────────────────────
    if peas_has_tool nmap; then
        local vnc_auth
        vnc_auth="$(peas_exec_silent 15 nmap -p "$port" --script=vnc-info,vnc-brute "$host" 2>/dev/null || echo "")"
        if [[ -n "$vnc_auth" ]]; then
            echo "$vnc_auth" >> "$output_file"

            if echo "$vnc_auth" | grep -qi "No authentication\|none"; then
                peas_add_finding "$host" "$port" "vnc" "auth" "critical" "confirmed" \
                    "VNC without authentication" "Remote desktop accessible without password" "nmap" \
                    "Configure VNC authentication immediately"
            fi

            if echo "$vnc_auth" | grep -qi "password"; then
                local pw_type="$(echo "$vnc_auth" | grep -i "password" | head -1)"
                peas_add_finding "$host" "$port" "vnc" "auth" "medium" "observed" \
                    "VNC authentication type" "$pw_type" "nmap" \
                    "Use strong VNC password, consider SSH tunnel"
            fi
        fi
    fi

    # ── Check for VNC on common ports ──────────────────────────────────
    if [[ "$port" == "5900" || "$port" == "5901" || "$port" == "5902" ]]; then
        peas_add_finding "$host" "$port" "vnc" "info" "info" "observed" \
            "VNC on standard port" "Port $port is standard VNC display" "nmap" \
            "Restrict VNC access with firewall rules"
    fi

    # ── Intelligence ────────────────────────────────────────────────────
    local exploit_results
    exploit_results="$(peas_searchsploit "VNC" 3 2>/dev/null || echo "")"
    if [[ -n "$exploit_results" ]]; then
        echo "$exploit_results" >> "$output_file"
        peas_add_finding "$host" "$port" "vnc" "cve" "medium" "likely" \
            "Known VNC exploits" "$exploit_results" "searchsploit" \
            "Review and patch"
    fi

    return 0
}