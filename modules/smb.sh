#!/usr/bin/env bash
[[ -n "${_NETPEAS_MODULE_SMB_LOADED:-}" ]] && return 0
readonly _NETPEAS_MODULE_SMB_LOADED=1

smb_module() {
    local host="$1"
    local port="$2"
    local state_dir="$3"

    local output_file="${state_dir}/smb_${host}_${port}.txt"
    : > "$output_file"

    peas_info "SMB — $host:$port"

    # ── enum4linux-ng (preferred) ────────────────────────────────────────────
    if peas_has_tool enum4linux-ng; then
        local enum_output
        enum_output="$(peas_exec_silent 30 enum4linux-ng -A "$host" 2>/dev/null || echo "")"
        if [[ -n "$enum_output" ]]; then
            echo "$enum_output" > "$output_file"

            # Check for null session
            if echo "$enum_output" | grep -qi "session setup.*success\|null session"; then
                peas_add_finding "$host" "$port" "smb" "null_session" "high" confirmed                     "Null session access allowed" "enum4linux-ng succeeded" "enum4linux-ng"                     "Disable null session access"
            fi

            # Check for shares
            local shares="$(echo "$enum_output" | grep -A100 'SHARES' | grep -v '^[[:space:]]*$' | head -20)"
            if [[ -n "$shares" ]]; then
                peas_add_finding "$host" "$port" "smb" "shares" "medium" observed                     "SMB shares enumerated" "$shares" "enum4linux-ng"                     "Review share permissions"
            fi

            # Check for users
            local users="$(echo "$enum_output" | grep -A100 'USERS' | head -20)"
            if [[ -n "$users" ]]; then
                peas_add_finding "$host" "$port" "smb" "users" "medium" observed                     "SMB users enumerated" "$users" "enum4linux-ng"                     "Review user list exposure"
            fi

            # Check for password policy
            local pass_policy="$(echo "$enum_output" | grep -A10 'PASSWORD POLICY')"
            if [[ -n "$pass_policy" ]]; then
                peas_add_finding "$host" "$port" "smb" "policy" "low" observed                     "Password policy enumerated" "$pass_policy" "enum4linux-ng"                     "Review password policy"
            fi
        fi
        return 0
    fi

    # ── smbclient fallback ───────────────────────────────────────────────────
    if peas_has_tool smbclient; then
        local share_list
        share_list="$(peas_exec_silent 10 smbclient -L "//$host" -N 2>/dev/null || echo "")"
        if [[ -n "$share_list" ]]; then
            echo "$share_list" > "$output_file"

            if echo "$share_list" | grep -qi "session setup.*success\|anonymous login"; then
                peas_add_finding "$host" "$port" "smb" "null_session" "high" confirmed                     "Null session access allowed" "smbclient anonymous login succeeded" "smbclient"                     "Disable null session access"
            fi

            local shares="$(echo "$share_list" | grep -E '^\s+\w+' | grep -v 'IPC\$' | head -10)"
            if [[ -n "$shares" ]]; then
                peas_add_finding "$host" "$port" "smb" "shares" "medium" observed                     "SMB shares enumerated" "$shares" "smbclient"                     "Review share permissions"
            fi
        fi
        return 0
    fi

    # ── rpcclient fallback ───────────────────────────────────────────────────
    if peas_has_tool rpcclient; then
        local rpc_output
        rpc_output="$(peas_exec_silent 10 rpcclient -U "" -N "$host" -c 'srvinfo' 2>/dev/null || echo "")"
        if [[ -n "$rpc_output" ]]; then
            echo "$rpc_output" > "$output_file"
            if echo "$rpc_output" | grep -qi "NT_STATUS"; then
                peas_add_finding "$host" "$port" "smb" "rpc" "medium" observed                     "RPC response received" "$rpc_output" "rpcclient"                     "Review RPC access"
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
            peas_add_finding "$host" "$port" "smb" "info" "info" observed                 "SMB Service" "Banner: ${banner:0:100}" "nc"                 "Verify SMB configuration"
        fi
    fi

    peas_add_finding "$host" "$port" "smb" "info" "info" observed         "SMB Service" "Port $port/tcp" "port" "Ensure SMB signing is enabled"
}
