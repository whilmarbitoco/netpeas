#!/usr/bin/env bash
#
# NetPEAS — modules/imap.sh
# IMAP service enumeration
#

imap_module() {
    local host="$1"
    local port="$2"
    local state_dir="$3"

    local output_file="${state_dir}/imap_${host}_${port}.txt"
    : > "$output_file"

    peas_info "IMAP — $host:$port"

    # ── Banner Grab ────────────────────────────────────────────────────
    local banner=""
    if peas_has_tool nc; then
        banner="$(peas_exec_silent 5 bash -c "echo | timeout 5 nc -w3 $host $port 2>/dev/null")"
        echo "$banner" > "$output_file"
    fi

    if [[ -n "$banner" ]]; then
        local version="$(echo "$banner" | grep -oP '(?<=IMAP4rev1|IMAP4).*' | head -1)"
        peas_add_finding "$host" "$port" "imap" "info" "info" "observed" \
            "IMAP service detected" "Banner: ${banner:0:100}" "nc" \
            "Verify IMAP requires authentication"

        # Check for cleartext auth
        if echo "$banner" | grep -qi "IMAP4"; then
            peas_add_finding "$host" "$port" "imap" "protocol" "medium" "observed" \
                "IMAP without TLS" "Credentials transmitted in cleartext" "nc" \
                "Enable IMAPS (SSL/TLS) for encrypted communication"
        fi
    fi

    # ── User Enumeration ───────────────────────────────────────────────
    local test_users=("root" "admin" "user" "test" "info" "mail")
    local found_user=""

    for user in "${test_users[@]}"; do
        if peas_has_tool nc; then
            local enum_test
            enum_test="$(peas_exec_silent 5 bash -c "echo -e '1 LOGIN $user test\r\n2 LOGOUT' | timeout 5 nc -w3 $host $port 2>/dev/null")"
            if echo "$enum_test" | grep -qi "OK" && ! echo "$enum_test" | grep -qi "unknown\|failed"; then
                found_user="$user"
                peas_add_finding "$host" "$port" "imap" "enum" "medium" "confirmed" \
                    "IMAP user enumeration possible" "User $user exists" "nc" \
                    "Disable IMAP or implement account lockout"
                break
            fi
        fi
    done

    # ── Intelligence ────────────────────────────────────────────────────
    local exploit_results
    exploit_results="$(peas_searchsploit "IMAP" 3 2>/dev/null || echo "")"
    if [[ -n "$exploit_results" ]]; then
        echo "$exploit_results" >> "$output_file"
    fi

    return 0
}