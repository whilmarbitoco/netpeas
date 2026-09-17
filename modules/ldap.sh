#!/usr/bin/env bash
#
# NetPEAS — modules/ldap.sh
# LDAP service enumeration.
#



ldap_module() {
    local host="$1"
    local port="$2"
    local state_dir="$3"

    local output_file="${state_dir}/ldap_${host}_${port}.txt"
    : > "$output_file"

    peas_info "LDAP — $host:$port"

    if ! peas_has_tool ldapsearch; then
        peas_warn "ldapsearch not available; skipping LDAP"
        return 1
    fi

    # Anonymous bind
    local result
    result="$(peas_exec_silent 10 ldapsearch -x -H "ldap://${host}:${port}" -s base namingContexts 2>/dev/null || echo "")"
    echo "$result" > "$output_file"

    if echo "$result" | grep -q "namingContexts"; then
        peas_finding "medium" "LDAP anonymous bind allowed"
        peas_add_finding "$host" "$port" "ldap" "auth" "high" "confirmed" \
            "LDAP anonymous bind" "Server returned data without credentials" "ldapsearch" \
            "Disable anonymous LDAP bind"
    fi
    return 0
}

