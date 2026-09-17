#!/usr/bin/env bash
[[ -n "${_NETPEAS_MODULE_REDIS_LOADED:-}" ]] && return 0
readonly _NETPEAS_MODULE_REDIS_LOADED=1

redis_module() {
    local host="$1"
    local port="$2"
    local state_dir="$3"

    local output_file="${state_dir}/redis_${host}_${port}.txt"
    : > "$output_file"

    peas_info "Redis — $host:$port"

    # ── INFO Command (unauthenticated) ───────────────────────────────────────
    local info_output=""
    if peas_has_tool redis-cli; then
        info_output="$(peas_exec_silent 10 redis-cli -h "$host" -p "$port" INFO 2>/dev/null || echo "")"
    fi
    if [[ -z "$info_output" ]] && peas_has_tool nc; then
        info_output="$(peas_exec_silent 5 bash -c "echo -e \"INFO\r\nQUIT\r\n\" | timeout 5 nc -w3 $host $port 2>/dev/null" || echo "")"
    fi
    if [[ -z "$info_output" ]]; then
        peas_debug "Redis requires auth or unreachable"
        return 0
    fi
    echo "$info_output" > "$output_file"

    local version="$(echo "$info_output" | grep 'redis_version:' | cut -d: -f2 | tr -d '\r')"
    local mode="$(echo "$info_output" | grep 'redis_mode:' | cut -d: -f2 | tr -d '\r')"
    local os="$(echo "$info_output" | grep 'os:' | cut -d: -f2 | tr -d '\r')"
    local used_mem="$(echo "$info_output" | grep 'used_memory_human:' | cut -d: -f2 | tr -d '\r')"

    local title="Redis Service"
    [[ -n "$version" ]] && title="Redis $version"

    peas_add_finding "$host" "$port" "redis" "info" "info" observed         "$title" "Version: $version, Mode: $mode, OS: $os, Memory: $used_mem" "redis-cli/nc"         "Ensure Redis is not exposed without authentication"

    peas_add_finding "$host" "$port" "redis" "auth" "high" confirmed         "Unauthenticated Redis access" "INFO command succeeded" "redis-cli"         "Enable Redis authentication (requirepass)"

    # ── CONFIG GET ────────────────────────────────────────────────────────────
    local config_output=""
    if peas_has_tool redis-cli; then
        config_output="$(peas_exec_silent 10 redis-cli -h "$host" -p "$port" CONFIG GET \* 2>/dev/null || echo "")"
    fi
    if [[ -n "$config_output" ]]; then
        echo "$config_output" >> "$output_file"
        local requirepass="$(echo "$config_output" | grep 'requirepass' | head -1)"
        if [[ -z "$requirepass" || "$requirepass" == "requirepass" ]]; then
            peas_add_finding "$host" "$port" "redis" "auth" "critical" confirmed                 "Redis has no password configured" "requirepass not set" "redis-cli"                 "Set a strong password immediately"
        fi
    fi

    # ── Database Size ────────────────────────────────────────────────────────
    local dbsize=""
    if peas_has_tool redis-cli; then
        dbsize="$(peas_exec_silent 10 redis-cli -h "$host" -p "$port" DBSIZE 2>/dev/null || echo "")"
    fi
    if [[ -n "$dbsize" ]]; then
        echo "DBSIZE: $dbsize" >> "$output_file"
        peas_add_finding "$host" "$port" "redis" "data" "medium" observed             "Redis database has $dbsize keys" "Database accessible" "redis-cli"             "Review data exposure"
    fi
}
