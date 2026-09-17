#!/usr/bin/env bash
[[ -n "${_NETPEAS_MODULE_POSTGRES_LOADED:-}" ]] && return 0
readonly _NETPEAS_MODULE_POSTGRES_LOADED=1

postgres_module() {
    local host="$1"
    local port="$2"
    local state_dir="$3"

    local output_file="${state_dir}/postgres_${host}_${port}.txt"
    : > "$output_file"

    peas_info "PostgreSQL — $host:$port"

    # ── Trust Auth Test ──────────────────────────────────────────────────────
    if peas_has_tool psql; then
        local trust_test
        trust_test="$(peas_exec_silent 10 psql -h "$host" -p "$port" -U postgres -c \"SELECT version();\" 2>&1 || echo "")"
        if [[ -n "$trust_test" ]] && ! echo "$trust_test" | grep -qi "password authentication"; then
            peas_add_finding "$host" "$port" "postgres" "auth" "critical" confirmed                 "Trust authentication enabled" "Login without password" "psql"                 "Configure password authentication (md5/scram-sha-256)"
            echo "Trust auth: $trust_test" > "$output_file"
        fi
    fi

    # ── Banner Grab ──────────────────────────────────────────────────────────
    local banner=""
    if peas_has_tool nc; then
        banner="$(peas_exec_silent 5 bash -c "echo | timeout 5 nc -w3 $host $port 2>/dev/null" || echo "")"
    fi
    if [[ -n "$banner" ]]; then
        echo "$banner" >> "$output_file"
        local version="$(peas_extract_version "$banner")"
        [[ -n "$version" ]] && peas_add_finding "$host" "$port" "postgres" "info" "info" observed             "PostgreSQL $version" "Banner: ${banner:0:100}" "nc" "Verify configuration"
    fi
}
