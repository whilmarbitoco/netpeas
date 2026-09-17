#!/usr/bin/env bash
#
# NetPEAS — modules/https.sh
# HTTPS service enumeration (HTTP + TLS).
#

[[ -n "${_NETPEAS_MODULE_HTTPS_LOADED:-}" ]] && return 0
readonly _NETPEAS_MODULE_HTTPS_LOADED=1


https_module() {
    local host="$1"
    local port="$2"
    local state_dir="$3"

    local output_file="${state_dir}/https_${host}_${port}.txt"
    : > "$output_file"

    peas_info "HTTPS — $host:$port"

    if ! peas_has_tool curl; then
        peas_warn "curl not available; skipping HTTPS"
        return 1
    fi

    # HTTP headers over TLS
    local headers
    headers="$(peas_exec_silent 10 curl -sIk --connect-timeout 5 "https://${host}:${port}" 2>/dev/null || echo "")"
    echo "$headers" > "$output_file"

    local server="$(echo "$headers" | grep -i '^server:' | head -1 | cut -d: -f2- | xargs)"
    local title="HTTPS Service"
    [[ -n "$server" ]] && title="HTTPS — $server"

    peas_add_finding "$host" "$port" "https" "info" "info" "observed" \
        "$title" "Server: ${server:-unknown}" "curl" "Review HTTPS configuration"

    # TLS fingerprint
    if peas_has_tool openssl; then
        local tls_info
        tls_info="$(peas_exec_silent 10 echo | openssl s_client -connect "${host}:${port}" -servername "$host" 2>/dev/null | head -20)"
        if [[ -n "$tls_info" ]]; then
            echo "$tls_info" >> "$output_file"
            local tls_version="$(echo "$tls_info" | grep -oP 'Protocol\s*:\s*\K.*' | head -1)"
            [[ -n "$tls_version" ]] && peas_detail "TLS: $tls_version"
        fi
    fi

    # SearchSploit
    if [[ -n "$server" ]]; then
        local version="$(peas_extract_version "$server")"
        [[ -n "$version" ]] && peas_searchsploit "$server" 3 2>/dev/null >> "$output_file" || true
    fi
}

