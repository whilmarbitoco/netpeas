#!/usr/bin/env bash
#
# NetPEAS — modules/http.sh
# HTTP/HTTPS service enumeration.
#

[[ -n "${_NETPEAS_MODULE_HTTP_LOADED:-}" ]] && return 0
readonly _NETPEAS_MODULE_HTTP_LOADED=1

set -Eeuo pipefail

# ── HTTP module ───────────────────────────────────────────────────────────────

http_module() {
    local host="$1"
    local port="$2"
    local state_dir="$3"

    local output_file="${state_dir}/http_${host}_${port}.txt"
    : > "$output_file"

    peas_info "HTTP — $host:$port"

    # PRECHECK
    if ! peas_has_tool curl; then
        peas_warn "curl not available; skipping HTTP enumeration"
        return 1
    fi

    # ENUMERATE — headers
    local headers
    headers="$(peas_exec_silent 10 curl -sI -k --connect-timeout 5 "http://${host}:${port}" 2>/dev/null || echo "")"

    if [[ -z "$headers" ]]; then
        peas_debug "No HTTP response"
        return 0
    fi

    echo "$headers" > "$output_file"

    # PARSE — server, tech, etc.
    local server
    server="$(echo "$headers" | grep -i '^server:' | head -1 | cut -d: -f2- | xargs)"
    local x_powered_by
    x_powered_by="$(echo "$headers" | grep -i '^x-powered-by:' | head -1 | cut -d: -f2- | xargs)"

    local title="HTTP Service"
    [[ -n "$server" ]] && title="HTTP — $server"

    # ANALYZE
    local evidence=""
    [[ -n "$server" ]] && evidence="Server: $server"
    [[ -n "$x_powered_by" ]] && evidence="${evidence:+$evidence, }X-Powered-By: $x_powered_by"

    local confidence="observed"
    if [[ -n "$server" ]]; then
        confidence="high"
    fi

    # FINDING
    peas_add_finding "$host" "$port" "http" "info" "info" "$confidence" \
        "$title" "$evidence" "curl" "Review exposed server technologies"

    # INTELLIGENCE
    if [[ -n "$server" ]]; then
        local version
        version="$(peas_extract_version "$server")"
        if [[ -n "$version" ]]; then
            local exploit_results
            exploit_results="$(peas_searchsploit "$server" 3 2>/dev/null || echo "")"
            if [[ -n "$exploit_results" ]]; then
                peas_finding "medium" "Exploits available for $server"
                echo "$exploit_results" >> "$output_file"
            fi
        fi
    fi
}

