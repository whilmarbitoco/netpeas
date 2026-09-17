#!/usr/bin/env bash
#
# NetPEAS — modules/postgres.sh
# PostgreSQL service enumeration.
#

[[ -n "${_NETPEAS_MODULE_POSTGRES_LOADED:-}" ]] && return 0
readonly _NETPEAS_MODULE_POSTGRES_LOADED=1

set -Eeuo pipefail

postgres_module() {
    local host="$1"
    local port="$2"
    local state_dir="$3"

    local output_file="${state_dir}/postgres_${host}_${port}.txt"
    : > "$output_file"

    peas_info "PostgreSQL — $host:$port"

    if ! peas_has_tool psql; then
        peas_warn "psql not available; skipping PostgreSQL"
        return 1
    fi

    # Try trust/no-pass
    local result
    result="$(PGPASSWORD="" peas_exec_silent 10 psql -h "$host" -p "$port" -U postgres -c "SELECT version();" 2>&1 || echo "")"
    echo "$result" > "$output_file"

    if echo "$result" | grep -qi "PostgreSQL"; then
        peas_finding "high" "PostgreSQL accessible without proper auth"
        peas_add_finding "$host" "$port" "postgres" "auth" "high" "likely" \
            "PostgreSQL accessible" "Connection attempt returned version" "psql" \
            "Verify pg_hba.conf authentication rules"
    fi
}

