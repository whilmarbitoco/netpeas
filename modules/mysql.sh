#!/usr/bin/env bash
[[ -n "${_NETPEAS_MODULE_MYSQL_LOADED:-}" ]] && return 0
readonly _NETPEAS_MODULE_MYSQL_LOADED=1

mysql_module() {
    local host="$1"
    local port="$2"
    local state_dir="$3"

    local output_file="${state_dir}/mysql_${host}_${port}.txt"
    : > "$output_file"

    peas_info "MySQL — $host:$port"

    # ── Banner Grab ──────────────────────────────────────────────────────────
    local banner=""
    if peas_has_tool nc; then
        banner="$(peas_exec_silent 5 bash -c "echo | timeout 5 nc -w3 $host $port 2>/dev/null" || echo "")"
    fi
    if [[ -z "$banner" ]]; then
        peas_debug "Cannot reach MySQL on $host:$port"
        return 0
    fi
    echo "$banner" > "$output_file"

    local version="$(peas_extract_version "$banner")"
    local title="MySQL Service"
    [[ -n "$version" ]] && title="MySQL $version"

    peas_add_finding "$host" "$port" "mysql" "info" "info" observed         "$title" "Banner: ${banner:0:100}" "nc" "Verify MySQL configuration"

    # ── Root No-Password Test ────────────────────────────────────────────────
    if peas_has_tool mysql; then
        local login_test
        login_test="$(peas_exec_silent 10 mysql -h "$host" -P "$port" -u root -e \"SELECT VERSION();\" 2>&1 || echo "")"
        if [[ -n "$login_test" ]] && ! echo "$login_test" | grep -qi "access denied"; then
            peas_add_finding "$host" "$port" "mysql" "auth" "critical" confirmed                 "Root login without password" "Login succeeded" "mysql"                 "Set a strong root password"
            echo "Root login: $login_test" >> "$output_file"
        fi
    fi

    # ── Anonymous Access ──────────────────────────────────────────────────────
    if peas_has_tool mysql; then
        local anon_test
        anon_test="$(peas_exec_silent 10 mysql -h "$host" -P "$port" -u \"\" -e \"SELECT 1;\" 2>&1 || echo "")"
        if [[ -n "$anon_test" ]] && ! echo "$anon_test" | grep -qi "access denied"; then
            peas_add_finding "$host" "$port" "mysql" "auth" "high" confirmed                 "Anonymous MySQL access" "Login succeeded" "mysql"                 "Disable anonymous access"
        fi
    fi
}
