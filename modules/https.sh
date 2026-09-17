#!/usr/bin/env bash

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

    # ── Headers ───────────────────────────────────────────────────────────────
    local headers
    headers="$(peas_exec_silent 10 curl -sIk --connect-timeout 5 "https://${host}:${port}" 2>/dev/null || echo "")"
    if [[ -z "$headers" ]]; then
        peas_debug "No HTTPS response"
        return 0
    fi
    echo "$headers" > "$output_file"

    local server="$(echo "$headers" | grep -i '^server:' | head -1 | cut -d: -f2- | xargs)"
    local x_powered_by="$(echo "$headers" | grep -i '^x-powered-by:' | head -1 | cut -d: -f2- | xargs)"

    local title="HTTPS Service"
    [[ -n "$server" ]] && title="HTTPS — $server"

    local evidence=""
    [[ -n "$server" ]] && evidence="Server: $server"
    [[ -n "$x_powered_by" ]] && evidence="${evidence:+$evidence, }X-Powered-By: $x_powered_by"

    peas_add_finding "$host" "$port" "https" "info" "info" observed         "$title" "$evidence" "curl" "Review HTTPS configuration"

    # ── TLS Version Detection ─────────────────────────────────────────────────
    if peas_has_tool openssl; then
        local tls_version
        tls_version="$(peas_exec_silent 10 openssl s_client -connect "${host}:${port}" -servername "$host" </dev/null 2>/dev/null | grep -i 'protocol' | head -1)"
        if [[ -n "$tls_version" ]]; then
            echo "$tls_version" >> "$output_file"
            if echo "$tls_version" | grep -qi "sslv3\|tlsv1\."; then
                peas_add_finding "$host" "$port" "https" "tls" "high" confirmed                     "Weak TLS version" "$tls_version" "openssl"                     "Disable SSLv3/TLS 1.0/TLS 1.1"
            fi
        fi
    fi

    # ── Certificate Inspection ────────────────────────────────────────────────
    if peas_has_tool openssl; then
        local cert_info
        cert_info="$(peas_exec_silent 10 openssl s_client -connect "${host}:${port}" -servername "$host" </dev/null 2>/dev/null | openssl x509 -noout -dates -subject -issuer 2>/dev/null || echo "")"
        if [[ -n "$cert_info" ]]; then
            echo "$cert_info" >> "$output_file"
            local not_after="$(echo "$cert_info" | grep 'notAfter=' | cut -d= -f2)"
            local subject="$(echo "$cert_info" | grep 'subject=' | cut -d= -f2-)"
            local issuer="$(echo "$cert_info" | grep 'issuer=' | cut -d= -f2-)"

            # Check expiry
            if [[ -n "$not_after" ]]; then
                local expiry_epoch="$(date -d "$not_after" +%s 2>/dev/null || echo 0)"
                local now_epoch="$(date +%s)"
                if [[ $expiry_epoch -lt $now_epoch ]]; then
                    peas_add_finding "$host" "$port" "https" "cert" "critical" confirmed                         "Expired SSL certificate" "Expired: $not_after" "openssl"                         "Renew certificate immediately"
                elif [[ $(( (expiry_epoch - now_epoch) / 86400 )) -lt 30 ]]; then
                    peas_add_finding "$host" "$port" "https" "cert" "medium" confirmed                         "SSL certificate expiring soon" "Expires: $not_after" "openssl"                         "Renew certificate"
                fi
            fi

            # Check self-signed
            if [[ -n "$subject" && -n "$issuer" && "$subject" == "$issuer" ]]; then
                peas_add_finding "$host" "$port" "https" "cert" "medium" confirmed                     "Self-signed certificate" "Subject: $subject" "openssl"                     "Use a certificate from a trusted CA"
            fi
        fi
    fi

    # ── Cipher Suite Enumeration ──────────────────────────────────────────────
    if peas_has_tool sslscan; then
        local cipher_output
        cipher_output="$(peas_exec_silent 15 sslscan --no-colour "${host}:${port}" 2>/dev/null || echo "")"
        if [[ -n "$cipher_output" ]]; then
            echo "$cipher_output" >> "$output_file"
            local weak_ciphers="$(echo "$cipher_output" | grep -i 'RC4\|DES\|MD5\|NULL\|EXP' | head -5)"
            if [[ -n "$weak_ciphers" ]]; then
                peas_add_finding "$host" "$port" "https" "cipher" "high" observed                     "Weak cipher suites supported" "$weak_ciphers" "sslscan"                     "Disable weak cipher suites"
            fi
        fi
    fi

    # ── Intelligence ─────────────────────────────────────────────────────────
    if [[ -n "$server" ]]; then
        local version="$(peas_extract_version "$server")"
        if [[ -n "$version" ]]; then
            local exploit_results="$(peas_searchsploit "$server" 5 2>/dev/null || echo "")"
            if [[ -n "$exploit_results" ]]; then
                peas_add_finding "$host" "$port" "https" "cve" "medium" likely                     "Known exploits for $server" "$exploit_results" "searchsploit"                     "Review and patch"
                echo "$exploit_results" >> "$output_file"
            fi
        fi
    fi
    return 0
}
