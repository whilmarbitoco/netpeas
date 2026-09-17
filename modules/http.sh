#!/usr/bin/env bash

http_module() {
    local host="$1"
    local port="$2"
    local state_dir="$3"

    local output_file="${state_dir}/http_${host}_${port}.txt"
    : > "$output_file"

    peas_info "HTTP — $host:$port"

    if ! peas_has_tool curl; then
        peas_warn "curl not available; skipping HTTP enumeration"
        return 1
    fi

    # ── Headers ───────────────────────────────────────────────────────────────
    local headers
    headers="$(peas_exec_silent 10 curl -sI -k --connect-timeout 5 "http://${host}:${port}" 2>/dev/null || echo "")"
    if [[ -z "$headers" ]]; then
        peas_debug "No HTTP response"
        return 0
    fi
    echo "$headers" > "$output_file"

    local server="$(echo "$headers" | grep -i '^server:' | head -1 | cut -d: -f2- | xargs)"
    local x_powered_by="$(echo "$headers" | grep -i '^x-powered-by:' | head -1 | cut -d: -f2- | xargs)"
    local x_frame_options="$(echo "$headers" | grep -i '^x-frame-options:' | head -1 | cut -d: -f2- | xargs)"
    local x_content_type="$(echo "$headers" | grep -i '^x-content-type-options:' | head -1 | cut -d: -f2- | xargs)"
    local csp="$(echo "$headers" | grep -i '^content-security-policy:' | head -1 | cut -d: -f2- | xargs)"
    local hsts="$(echo "$headers" | grep -i '^strict-transport-security:' | head -1 | cut -d: -f2- | xargs)"

    local title="HTTP Service"
    [[ -n "$server" ]] && title="HTTP — $server"

    local evidence=""
    [[ -n "$server" ]] && evidence="Server: $server"
    [[ -n "$x_powered_by" ]] && evidence="${evidence:+$evidence, }X-Powered-By: $x_powered_by"

    # Basic finding for service detection
    peas_add_finding "$host" "$port" "http" "info" "info" observed         "$title" "$evidence" "curl" "Review exposed server technologies"

    # Security headers check
    local missing_headers=""
    [[ -z "$hsts" ]] && missing_headers="${missing_headers:+$missing_headers, }HSTS"
    [[ -z "$csp" ]] && missing_headers="${missing_headers:+$missing_headers, }CSP"
    [[ -z "$x_frame_options" ]] && missing_headers="${missing_headers:+$missing_headers, }X-Frame-Options"
    [[ -z "$x_content_type" ]] && missing_headers="${missing_headers:+$missing_headers, }X-Content-Type-Options"

    if [[ -n "$missing_headers" ]]; then
        peas_add_finding "$host" "$port" "http" "headers" "medium" observed             "Missing security headers" "Missing: $missing_headers" "curl"             "Implement missing security headers"
    fi

    # ── OPTIONS method test ──────────────────────────────────────────────────
    local allow_methods
    allow_methods="$(peas_exec_silent 10 curl -s -o /dev/null -w "%{http_code}" -X OPTIONS --connect-timeout 5 "http://${host}:${port}" 2>/dev/null || echo "")"
    if [[ -n "$allow_methods" ]]; then
        local allow_header="$(peas_exec_silent 10 curl -sI -X OPTIONS --connect-timeout 5 "http://${host}:${port}" 2>/dev/null | grep -i '^allow:' | head -1)"
        if echo "$allow_header" | grep -qi "PUT\|DELETE\|TRACE"; then
            peas_add_finding "$host" "$port" "http" "method" "high" observed                 "Dangerous HTTP methods allowed" "$allow_header" "curl"                 "Disable unnecessary HTTP methods"
        fi
    fi

    # ── Common path probe ───────────────────────────────────────────────────
    local paths=("/robots.txt" "/sitemap.xml" "/admin" "/api" "/.env" "/.git" "/backup" "/config")
    local found_paths=""
    for path in "${paths[@]}"; do
        local http_code
        http_code="$(peas_exec_silent 5 curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 "http://${host}:${port}${path}" 2>/dev/null || echo "000")"
        if [[ "$http_code" == "200" ]]; then
            found_paths="${found_paths:+$found_paths, }${path}"
            echo "  $path -> $http_code" >> "$output_file"
        fi
    done

    if [[ -n "$found_paths" ]]; then
        local severity="medium"
        echo "$found_paths" | grep -q "\.env" && severity="critical"
        echo "$found_paths" | grep -q "\.git" && severity="critical"
        peas_add_finding "$host" "$port" "http" "path" "$severity" observed             "Common paths exposed" "Found: $found_paths" "curl"             "Remove or protect exposed paths"
    fi

    # ── Web technology fingerprinting (optional) ─────────────────────────────
    if peas_has_tool whatweb; then
        local tech_output
        tech_output="$(peas_exec_silent 15 whatweb --no-errors --color=never "http://${host}:${port}" 2>/dev/null || echo "")"
        if [[ -n "$tech_output" ]]; then
            echo "$tech_output" >> "$output_file"
            local techs="$(echo "$tech_output" | grep -oP '\[.*?\]' | tr '\n' ' ')"
            [[ -n "$techs" ]] && peas_detail "Technologies: $techs"
        fi
    fi

    # ── Intelligence ─────────────────────────────────────────────────────────
    if [[ -n "$server" ]]; then
        local version="$(peas_extract_version "$server")"
        if [[ -n "$version" ]]; then
            local exploit_results="$(peas_searchsploit "$server" 5 2>/dev/null || echo "")"
            if [[ -n "$exploit_results" ]]; then
                peas_add_finding "$host" "$port" "http" "cve" "medium" likely                     "Known exploits for $server" "$exploit_results" "searchsploit"                     "Review and patch"
                echo "$exploit_results" >> "$output_file"
            fi
        fi
    fi
    return 0
}
