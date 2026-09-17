#!/usr/bin/env bash
[[ -n "${_NETPEAS_MODULE_FTP_LOADED:-}" ]] && return 0
readonly _NETPEAS_MODULE_FTP_LOADED=1

ftp_module() {
    local host="$1"
    local port="$2"
    local state_dir="$3"

    local output_file="${state_dir}/ftp_${host}_${port}.txt"
    : > "$output_file"

    peas_info "FTP — $host:$port"

    # ── Banner Grab ──────────────────────────────────────────────────────────
    local banner=""
    if peas_has_tool nc; then
        banner="$(peas_exec_silent 5 bash -c "echo | timeout 5 nc -w3 $host $port 2>/dev/null" || echo "")"
    fi
    if [[ -z "$banner" ]]; then
        peas_debug "Cannot reach FTP on $host:$port"
        return 0
    fi
    echo "$banner" > "$output_file"

    local version="$(peas_extract_version "$banner")"
    local title="FTP Service"
    [[ -n "$version" ]] && title="FTP — $version"

    peas_add_finding "$host" "$port" "ftp" "info" "info" observed         "$title" "Banner: ${banner:0:100}" "nc" "Review FTP configuration"

    # ── Anonymous Login Test ─────────────────────────────────────────────────
    if peas_has_tool ftp; then
        local anon_test
        anon_test="$( (echo "USER anonymous"; echo "PASS anonymous"; echo "QUIT"; sleep 1) | peas_exec_silent 10 ftp -n "$host" "$port" 2>&1 || echo "")"
        if echo "$anon_test" | grep -q "230"; then
            peas_add_finding "$host" "$port" "ftp" "anonymous" "high" confirmed                 "Anonymous FTP login allowed" "Login succeeded" "ftp"                 "Disable anonymous FTP access"
        fi
    fi
}
