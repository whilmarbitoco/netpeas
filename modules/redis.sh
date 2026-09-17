#!/usr/bin/env bash
#
# NetPEAS — modules/redis.sh
# Redis service enumeration.
#



redis_module() {
    local host="$1"
    local port="$2"
    local state_dir="$3"

    local output_file="${state_dir}/redis_${host}_${port}.txt"
    : > "$output_file"

    peas_info "Redis — $host:$port"

    if ! peas_has_tool redis-cli; then
        peas_warn "redis-cli not available; skipping Redis"
        return 1
    fi

    # INFO command (unauthenticated)
    local result
    result="$(peas_exec_silent 10 redis-cli -h "$host" -p "$port" INFO 2>&1 || echo "")"
    echo "$result" > "$output_file"

    if echo "$result" | grep -q "redis_version"; then
        local version="$(echo "$result" | grep -oP 'redis_version:\K.*' | head -1)"
        peas_finding "high" "Redis unauthenticated access"
        peas_add_finding "$host" "$port" "redis" "auth" "high" "confirmed" \
            "Redis unauthenticated" "INFO command succeeded (v${version:-unknown})" "redis-cli" \
            "Enable Redis AUTH, disable dangerous commands"
        peas_searchsploit "Redis" 3 2>/dev/null >> "$output_file" || true
    fi
    return 0
}

