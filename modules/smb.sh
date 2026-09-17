#!/usr/bin/env bash
#
# NetPEAS — modules/smb.sh
# SMB/CIFS service enumeration.
#

[[ -n "${_NETPEAS_MODULE_SMB_LOADED:-}" ]] && return 0
readonly _NETPEAS_MODULE_SMB_LOADED=1


smb_module() {
    local host="$1"
    local port="$2"
    local state_dir="$3"

    local output_file="${state_dir}/smb_${host}_${port}.txt"
    : > "$output_file"

    peas_info "SMB — $host:$port"

    # PREFER: enum4linux-ng
    if peas_has_tool enum4linux-ng; then
        local enum_out
        enum_out="$(peas_exec_silent 30 enum4linux-ng -A "$host" 2>/dev/null || echo "")"
        echo "$enum_out" > "$output_file"

        local smb_info
        smb_info="$(echo "$enum_out" | grep -i 'os\|version\|samba' | head -5)"
        [[ -n "$smb_info" ]] && peas_detail "$smb_info"

        peas_add_finding "$host" "$port" "smb" "enum" "info" "high" \
            "SMB enumeration" "enum4linux-ng output" "enum4linux-ng" \
            "Review SMB shares and permissions"

    # FALLBACK: smbclient + rpcclient
    elif peas_has_tool smbclient; then
        local shares
        shares="$(peas_exec_silent 10 smbclient -L "\\\\$host" -N 2>/dev/null || echo "")"
        echo "$shares" > "$output_file"

        # Check for null session
        if echo "$shares" | grep -qi "share\|disk\|print"; then
            local anon_access="Null session — shares listed without credentials"
            peas_finding "medium" "SMB null session"
            peas_add_finding "$host" "$port" "smb" "auth" "high" "confirmed" \
                "Anonymous SMB access" "$anon_access" "smbclient" \
                "Disable null session access"
        fi

        if peas_has_tool rpcclient; then
            local rpc_info
            rpc_info="$(peas_exec_silent 10 rpcclient -U "" -N "$host" -c "srvinfo" 2>/dev/null || echo "")"
            [[ -n "$rpc_info" ]] && echo "$rpc_info" >> "$output_file"
        fi

    # FALLBACK: netcat banner
    elif peas_has_tool nc; then
        local banner
        banner="$(peas_exec_silent 5 bash -c "echo | timeout 5 nc -w3 $host $port 2>/dev/null")"
        echo "$banner" > "$output_file"
        peas_add_finding "$host" "$port" "smb" "info" "info" "observed" \
            "SMB port open" "Banner: ${banner:0:100}" "nc" \
            "Install enum4linux-ng or smbclient for full enumeration"

    else
        peas_warn "No SMB tools available (enum4linux-ng, smbclient, or nc required)"
        return 1
    fi
}

