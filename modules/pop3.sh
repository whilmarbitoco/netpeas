#!/usr/bin/env bash
#
# NetPEAS — modules/pop3.sh
# POP3 service enumeration
#

pop3_module() {
    local host="$1"
    local port="$2"
    local state_dir="$3"

    local output_file="${state_dir}/pop3_${host}_${port}.txt"
    : > "$output_file"

    peas_info "POP3 — $host:$port"

    # ── Banner Grab ────────────────────────────────────────────────────
    local banner=""
    if peas_has_tool nc; then
        banner="$(peas_exec_silent 5 bash -c "echo | timeout 5 nc -w3 $host $port 2>/dev/null")"
        echo "$banner" > "$output_file"
    fi

    if [[ -n "$banner" ]]; then
        peas_add_finding "$host" "$port" "pop3" "info" "info" "observed" \
            "POP3 service detected" "Banner: ${banner:0:100}" "nc" \
            "Verify POP3 requires authentication"

        # Check for cleartext auth
        if echo "$banner" | grep -qi "POP3"; then
            peas_add_finding "$host" "$port" "pop3" "protocol" "medium" "observed" \
                "POP3 without TLS" "Credentials transmitted in cleartext" "nc" \
                "Enable POP3S (SSL/TLS) for encrypted communication"
        fi
    fi

    # ── User Enumeration ───────────────────────────────────────────────
    local test_users=("root" "admin" "user" "test" "info" "mail")
    local found_user=""

    for user in "${test_users[@]}"; do
        if peas_has_tool nc; then
            local enum_test
            enum_test="$(peas_exec_silent 5 bash -c "echo -e 'USER $user\r\nPASS test\r\nQUIT' | timeout 5 nc -w3 $host $port 2>/dev/null")"
            if echo "$enum_test" | grep -q "+OK" && ! echo "$enum_test" | grep -qi "unknown"; then
                found_user="$user"
                peas_add_finding "$host" "$port" "pop3" "enum" "medium" "confirmed" \
                    "POP3 user enumeration possible" "User $user exists" "nc" \
                    "Disable POP3 or implement account lockout"
                break
            fi
        fi
    done

    # ── Intelligence ────────────────────────────────────────────────────
    local exploit_results
    exploit_results="$(peas_searchsploit "POP3" 3 2>/dev/null || echo "")"
    if [[ -n "$exploit_results" ]]; then
        echo "$exploit_results" >> "$output_file"
    fi

    return 0
}