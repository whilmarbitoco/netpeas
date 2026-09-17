#!/usr/bin/env bash
#
# NetPEAS — modules/nfs.sh
# NFS service enumeration
#

nfs_module() {
    local host="$1"
    local port="$2"
    local state_dir="$3"

    local output_file="${state_dir}/nfs_${host}_${port}.txt"
    : > "$output_file"

    peas_info "NFS — $host:$port"

    # ── Show Available Exports ──────────────────────────────────────────
    local exports=""
    if peas_has_tool showmount; then
        exports="$(peas_exec_silent 10 showmount -e "$host" 2>&1 || echo "")"
        echo "$exports" > "$output_file"
    elif peas_has_tool nmap; then
        exports="$(peas_exec_silent 15 nmap -sV -p "$port" --script=nfs-showmount "$host" 2>/dev/null || echo "")"
        echo "$exports" > "$output_file"
    fi

    if [[ -n "$exports" ]] && ! echo "$exports" | grep -qi "denied\|error\|failed"; then
        local export_list="$(echo "$exports" | grep -v "^Export" | grep -v "^$" | head -10)"
        if [[ -n "$export_list" ]]; then
            peas_add_finding "$host" "$port" "nfs" "share" "high" "confirmed" \
                "NFS exports visible" "Exports: $(echo "$export_list" | tr '\n' ', ')" "showmount/nmap" \
                "Restrict NFS export visibility and enforce authentication"

            # Check for world-readable exports
            echo "$exports" | grep -qi "everyone\|all_squash\|no_root_squash"
            if [[ $? -eq 0 ]]; then
                peas_add_finding "$host" "$port" "nfs" "config" "critical" "confirmed" \
                    "Insecure NFS export configuration" "World-mapped or no_root_squash exports found" "showmount" \
                    "Use root_squash, restrict to specific hosts"
            fi
        fi
    fi

    # ── NFS Version & Protocol Detection ────────────────────────────────
    if peas_has_tool nmap; then
        local nfs_info
        nfs_info="$(peas_exec_silent 15 nmap -sV -p "$port" --script=nfs-ls,nfs-statfs "$host" 2>/dev/null || echo "")"
        if [[ -n "$nfs_info" ]]; then
            echo "$nfs_info" >> "$output_file"

            if echo "$nfs_info" | grep -qi "nfsv3\|nfsv4"; then
                local nfs_ver="$(echo "$nfs_info" | grep -oP 'NFSv[34]')"
                peas_add_finding "$host" "$port" "nfs" "info" "info" "observed" \
                    "NFS service detected" "$nfs_ver" "nmap" \
                    "Verify NFS access controls are properly configured"
            fi
        fi
    fi

    # ── RPC Information ────────────────────────────────────────────────
    if peas_has_tool rpcinfo; then
        local rpc_info
        rpc_info="$(peas_exec_silent 10 rpcinfo -p "$host" 2>/dev/null | grep -i "nfs\|mount\|nlockmgr" || echo "")"
        if [[ -n "$rpc_info" ]]; then
            echo "$rpc_info" >> "$output_file"
        fi
    fi

    # ── Attempt Mount Test (if possible) ────────────────────────────────
    # Note: mounting requires root, so we skip but report
    peas_add_finding "$host" "$port" "nfs" "info" "info" "observed" \
        "NFS port open" "Port $port/tcp open" "nmap" \
        "Verify NFS exports are properly secured"

    # ── Intelligence ────────────────────────────────────────────────────
    local exploit_results
    exploit_results="$(peas_searchsploit "NFS" 3 2>/dev/null || echo "")"
    if [[ -n "$exploit_results" ]]; then
        echo "$exploit_results" >> "$output_file"
        peas_add_finding "$host" "$port" "nfs" "cve" "medium" "likely" \
            "Known NFS exploits" "$exploit_results" "searchsploit" \
            "Review and patch"
    fi

    return 0
}