#!/usr/bin/env bash
#
# NetPEAS — modules/rdp.sh
# RDP service enumeration
#

rdp_module() {
    local host="$1"
    local port="$2"
    local state_dir="$3"

    local output_file="${state_dir}/rdp_${host}_${port}.txt"
    : > "$output_file"

    peas_info "RDP — $host:$port"

    # ── NLA (Network Level Authentication) Check ───────────────────────
    if peas_has_tool nmap; then
        local rdp_info
        rdp_info="$(peas_exec_silent 15 nmap -p "$port" --script=rdp-enum-encryption,rdp-vuln-ms12-020 "$host" 2>/dev/null || echo "")"
        echo "$rdp_info" > "$output_file"

        if [[ -n "$rdp_info" ]]; then
            # Check for BlueKeep CVE-2019-0708
            if echo "$rdp_info" | grep -qi "CVE-2019-0708\|BlueKeep\|vulnerable"; then
                peas_add_finding "$host" "$port" "rdp" "rce" "critical" "confirmed" \
                    "BlueKeep (CVE-2019-0708) vulnerable" "RDP pre-authentication remote code execution" "nmap" \
                    "Apply Microsoft security patch immediately"
            fi

            # Check for MS12-020
            if echo "$rdp_info" | grep -qi "MS12-020"; then
                peas_add_finding "$host" "$port" "rdp" "rce" "critical" "confirmed" \
                    "MS12-020 RDP vulnerability" "Remote code execution via RDP" "nmap" \
                    "Apply Microsoft security patch immediately"
            fi

            # Check NLA enforcement
            if echo "$rdp_info" | grep -qi "NLA: No\|NLA not\|CredSSP: No"; then
                peas_add_finding "$host" "$port" "rdp" "auth" "high" "confirmed" \
                    "NLA not enforced" "RDP does not require Network Level Authentication" "nmap" \
                    "Enable NLA to prevent unauthenticated access"
            fi

            # Check encryption level
            local enc_level="$(echo "$rdp_info" | grep -i "encryption" | head -1)"
            if echo "$rdp_info" | grep -qi "Medium\|Low\|None"; then
                peas_add_finding "$host" "$port" "rdp" "crypto" "medium" "observed" \
                    "Weak RDP encryption" "$enc_level" "nmap" \
                    "Configure RDP to require High encryption"
            fi
        fi
    fi

    # ── RDP Banner Grab ────────────────────────────────────────────────
    if peas_has_tool nc; then
        local banner
        banner="$(peas_exec_silent 5 bash -c "printf '\x03\x00\x00\x13\x0e\xe0\x00\x00\x00\x00\x00\x01\x00\x08\x00\x03\x00\x00\x00' | timeout 5 nc -w3 $host $port 2>/dev/null | xxd | head -5")"
        echo "$banner" >> "$output_file"
    fi

    # ── SSL/TLS Check on RDP Gateway ───────────────────────────────────
    if [[ "$port" == "443" || "$port" == "3391" ]] && peas_has_tool openssl; then
        local tls_version
        tls_version="$(peas_exec_silent 10 openssl s_client -connect "${host}:${port}" </dev/null 2>/dev/null | grep -i 'protocol' | head -1)"
        if [[ -n "$tls_version" ]]; then
            if echo "$tls_version" | grep -qi "sslv3\|tlsv1\."; then
                peas_add_finding "$host" "$port" "rdp" "tls" "high" "confirmed" \
                    "Weak TLS on RDP Gateway" "$tls_version" "openssl" \
                    "Disable SSLv3/TLS 1.0/TLS 1.1"
            fi
        fi
    fi

    # ── Intelligence ────────────────────────────────────────────────────
    local exploit_results
    exploit_results="$(peas_searchsploit "Remote Desktop" 5 2>/dev/null || echo "")"
    if [[ -n "$exploit_results" ]]; then
        echo "$exploit_results" >> "$output_file"
        peas_add_finding "$host" "$port" "rdp" "cve" "medium" "likely" \
            "Known RDP exploits" "$exploit_results" "searchsploit" \
            "Review and patch"
    fi

    return 0
}