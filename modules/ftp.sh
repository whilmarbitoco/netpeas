#!/usr/bin/env bash
#
# NetPEAS — modules/ftp.sh
# FTP service enumeration.
#

[[ -n "${_NETPEAS_MODULE_FTP_LOADED:-}" ]] && return 0
readonly _NETPEAS_MODULE_FTP_LOADED=1

set -Eeuo pipefail

ftp_module() {
    local host="$1"
    local port="$2"
    local state_dir="$3"

    local output_file="${state_dir}/ftp_${host}_${port}.txt"
    : > "$output_file"

    peas_info "FTP — $host:$port"

    if ! peas_has_tool nc; then
        peas_warn "nc not available; skipping FTP"
        return 1
    fi

    # Banner
    local banner
    banner="$(peas_exec_silent 5 bash -c "echo | timeout 5 nc -w3 $host $port 2>/dev/null")"
    echo "$banner" > "$output_file"

    local version="$(echo "$banner" | grep -oP '\d+\.\d+\.\d+' | head -1)"
    local title="FTP Service"
    [[ -n "$version" ]] && title="FTP — $version"

    peas_add_finding "$host" "$port" "ftp" "info" "info" "observed" \
        "$title" "Banner: ${banner:0:100}" "nc" "Check for anonymous login"

    # Check anonymous login
    local anon_test
    anon_test="$(peas_exec_silent 5 bash -c "echo -e 'USER anonymous\r\nQUIT' | timeout 5 nc -w3 $host $port 2>/dev/null")"
    if echo "$anon_test" | grep -q "230"; then
        peas_finding "medium" "Anonymous FTP login possible"
        peas_add_finding "$host" "$port" "ftp" "config" "high" "confirmed" \
            "Anonymous FTP login" "Server accepted anonymous credentials" "nc" \
            "Disable anonymous FTP access"
    fi

    [[ -n "$version" ]] && peas_searchsploit "FTP $version" 3 2>/dev/null >> "$output_file" || true
}

