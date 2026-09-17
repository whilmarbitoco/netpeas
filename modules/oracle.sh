#!/usr/bin/env bash
#
# NetPEAS — modules/oracle.sh
# Oracle Database enumeration (TNS)
#

oracle_module() {
    local host="$1"
    local port="$2"
    local state_dir="$3"

    local output_file="${state_dir}/oracle_${host}_${port}.txt"
    : > "$output_file"

    peas_info "Oracle TNS — $host:$port"

    # ── SID Enumeration ────────────────────────────────────────────────
    local sid_result=""
    if peas_has_tool nmap; then
        sid_result="$(peas_exec_silent 15 nmap -p "$port" --script=oracle-sid-brute "$host" 2>/dev/null || echo "")"
        echo "$sid_result" > "$output_file"
    fi

    if [[ -n "$sid_result" ]] && echo "$sid_result" | grep -qi "sid\|oracle"; then
        local sid="$(echo "$sid_result" | grep -oP 'SID:\s*\K\w+' | head -1)"
        if [[ -n "$sid" ]]; then
            peas_add_finding "$host" "$port" "oracle" "enum" "high" "confirmed" \
                "Oracle SID discovered" "SID: $sid" "nmap" \
                "Rename default SID, restrict TNS access"
        fi
    fi

    # ── TNS Poison Check ───────────────────────────────────────────────
    if peas_has_tool nmap; then
        local tns_poison
        tns_poison="$(peas_exec_silent 15 nmap -p "$port" --script=oracle-tns-poison "$host" 2>/dev/null || echo "")"
        if [[ -n "$tns_poison" ]] && echo "$tns_poison" | grep -qi "vulnerable"; then
            peas_add_finding "$host" "$port" "oracle" "tns" "critical" "confirmed" \
                "Oracle TNS Poison vulnerable" "Man-in-the-middle via TNS" "nmap" \
                "Apply Oracle patch for TNS poison"
        fi
    fi

    # ── Banner Grab ────────────────────────────────────────────────────
    if peas_has_tool nc; then
        local banner
        banner="$(peas_exec_silent 5 bash -c "echo -ne '(CONNECT_DATA=(COMMAND=version))' | timeout 5 nc -w3 $host $port 2>/dev/null | head -3")"
        echo "$banner" >> "$output_file"
        if [[ -n "$banner" ]]; then
            peas_add_finding "$host" "$port" "oracle" "info" "medium" "observed" \
                "Oracle TNS listener active" "Banner: ${banner:0:100}" "nc" \
                "Restrict TNS listener access"
        fi
    fi

    # ── Default Credentials Check ──────────────────────────────────────
    local default_sids=("ORCL" "XE" "ORCLPDB1" "PDB1" "TEST")
    local found_sid=""

    if peas_has_tool sqlplus; then
        for sid in "${default_sids[@]}"; do
            local test
            test="$(peas_exec_silent 10 echo "SELECT 1 FROM DUAL;" | sqlplus -s "sys/password@${host}:${port}/${sid}" 2>/dev/null || echo "")"
            if [[ -n "$test" ]] && echo "$test" | grep -qi "1"; then
                found_sid="$sid"
                peas_add_finding "$host" "$port" "oracle" "auth" "critical" "confirmed" \
                    "Oracle default credentials" "SYS account with default password on $sid" "sqlplus" \
                    "Change default passwords immediately"
                break
            fi
        done
    fi

    # ── Intelligence ────────────────────────────────────────────────────
    local exploit_results
    exploit_results="$(peas_searchsploit "Oracle Database" 5 2>/dev/null || echo "")"
    if [[ -n "$exploit_results" ]]; then
        echo "$exploit_results" >> "$output_file"
        peas_add_finding "$host" "$port" "oracle" "cve" "medium" "likely" \
            "Known Oracle DB exploits" "$exploit_results" "searchsploit" \
            "Review and patch"
    fi

    return 0
}