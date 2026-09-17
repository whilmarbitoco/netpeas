#!/usr/bin/env bash
[[ -n "${_NETPEAS_MODULE_LDAP_LOADED:-}" ]] && return 0
readonly _NETPEAS_MODULE_LDAP_LOADED=1

ldap_module() {
    local host="$1"
    local port="$2"
    local state_dir="$3"

    local output_file="${state_dir}/ldap_${host}_${port}.txt"
    : > "$output_file"

    peas_info "LDAP — $host:$port"

    # ── Anonymous Bind Test ──────────────────────────────────────────────────
    if peas_has_tool ldapsearch; then
        local anon_bind
        anon_bind="$(peas_exec_silent 10 ldapsearch -x -H "ldap://${host}:${port}" -s base -b "" 2>/dev/null || echo "")"
        if [[ -n "$anon_bind" ]]; then
            echo "$anon_bind" > "$output_file"
            peas_add_finding "$host" "$port" "ldap" "anonymous" "high" confirmed                 "Anonymous LDAP bind allowed" "Bind succeeded without credentials" "ldapsearch"                 "Require authentication for LDAP"

            # Extract naming contexts
            local naming_ctx="$(echo "$anon_bind" | grep 'namingContexts:' | head -5)"
            if [[ -n "$naming_ctx" ]]; then
                peas_add_finding "$host" "$port" "ldap" "info" "medium" observed                     "LDAP naming contexts exposed" "$naming_ctx" "ldapsearch"                     "Restrict LDAP information disclosure"
            fi
        fi
        return 0
    fi

    # ── Banner Grab (nc) ─────────────────────────────────────────────────────
    if peas_has_tool nc; then
        local banner=""
        banner="$(peas_exec_silent 5 bash -c "echo | timeout 5 nc -w3 $host $port 2>/dev/null" || echo "")"
        if [[ -n "$banner" ]]; then
            echo "$banner" > "$output_file"
            peas_add_finding "$host" "$port" "ldap" "info" "info" observed                 "LDAP Service" "Banner: ${banner:0:100}" "nc"                 "Verify LDAP configuration"
        fi
    fi

    peas_add_finding "$host" "$port" "ldap" "info" "info" observed         "LDAP Service" "Port $port/tcp" "port" "Ensure LDAP requires authentication"
}
