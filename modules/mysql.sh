#!/usr/bin/env bash
#
# NetPEAS — modules/mysql.sh
# MySQL service enumeration.
#



mysql_module() {
    local host="$1"
    local port="$2"
    local state_dir="$3"

    local output_file="${state_dir}/mysql_${host}_${port}.txt"
    : > "$output_file"

    peas_info "MySQL — $host:$port"

    if ! peas_has_tool mysql; then
        peas_warn "mysql client not available; skipping MySQL"
        return 1
    fi

    # Try anonymous/no-pass connection
    local result
    result="$(peas_exec_silent 10 mysql -h "$host" -P "$port" -u root --skip-password -e "SELECT 1" 2>&1 || echo "")"
    echo "$result" > "$output_file"

    if ! echo "$result" | grep -qi "denied\|error\|access"; then
        peas_finding "critical" "MySQL root without password"
        peas_add_finding "$host" "$port" "mysql" "auth" "critical" "confirmed" \
            "MySQL root login without password" "root login succeeded" "mysql" \
            "Set strong password for root"
    fi

    # Banner grab via nc
    if peas_has_tool nc; then
        local banner
        banner="$(peas_exec_silent 5 bash -c "echo | timeout 5 nc -w3 $host $port 2>/dev/null")"
        [[ -n "$banner" ]] && echo "$banner" >> "$output_file"
    fi
    return 0
}

