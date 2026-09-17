#!/usr/bin/env bash
[[ -n "${_NETPEAS_MODULE_DNS_LOADED:-}" ]] && return 0
readonly _NETPEAS_MODULE_DNS_LOADED=1

dns_module() {
    local host="$1"
    local port="$2"
    local state_dir="$3"

    local output_file="${state_dir}/dns_${host}_${port}.txt"
    : > "$output_file"

    peas_info "DNS — $host:$port"

    # ── Zone Transfer ────────────────────────────────────────────────────────
    if peas_has_tool dig; then
        local axfr
        axfr="$(peas_exec_silent 10 dig @"$host" -p "$port" example.com AXFR 2>/dev/null || echo "")"
        if echo "$axfr" | grep -q "Transfer succeeded"; then
            peas_add_finding "$host" "$port" "dns" "axfr" "high" confirmed                 "Zone transfer allows data exfiltration" "AXFR succeeded" "dig"                 "Restrict zone transfers to authorized hosts"
            echo "$axfr" > "$output_file"
        fi

        # ── DNSSEC Check ─────────────────────────────────────────────────────
        local dnskey
        dnskey="$(peas_exec_silent 10 dig @"$host" -p "$port" . DNSKEY +short 2>/dev/null || echo "")"
        if [[ -n "$dnskey" ]]; then
            echo "DNSKEY: $dnskey" >> "$output_file"
            peas_add_finding "$host" "$port" "dns" "dnssec" "info" observed                 "DNSSEC enabled" "DNSKEY found" "dig" "Good security posture"
        else
            peas_add_finding "$host" "$port" "dns" "dnssec" "medium" observed                 "DNSSEC not enabled" "No DNSKEY found" "dig"                 "Enable DNSSEC to prevent cache poisoning"
        fi

        # ── Open Resolver Test ───────────────────────────────────────────────
        local open_test
        open_test="$(peas_exec_silent 10 dig @"$host" -p "$port" google.com +short 2>/dev/null || echo "")"
        if [[ -n "$open_test" ]]; then
            peas_add_finding "$host" "$port" "dns" "open_resolver" "medium" observed                 "Open DNS resolver" "Recursive query succeeded" "dig"                 "Restrict recursive queries to authorized networks"
        fi

        # ── Version Query ────────────────────────────────────────────────────
        local version_bind
        version_bind="$(peas_exec_silent 10 dig @"$host" -p "$port" version.bind chaos txt 2>/dev/null || echo "")"
        if [[ -n "$version_bind" ]]; then
            echo "Version: $version_bind" >> "$output_file"
            peas_add_finding "$host" "$port" "dns" "version" "low" observed                 "DNS software version exposed" "$version_bind" "dig"                 "Disable version queries"
        fi

        # ── Subdomain Brute ──────────────────────────────────────────────────
        local subdomains="www mail ftp localhost admin webmail api ns1 ns2 mx ssh vpn"
        local found_subs=""
        for sub in $subdomains; do
            local sub_result
            sub_result="$(peas_exec_silent 5 dig @"$host" -p "$port" "${sub}.$host" +short 2>/dev/null || echo "")"
            if [[ -n "$sub_result" ]]; then
                found_subs="${found_subs:+$found_subs, }$sub ($sub_result)"
                echo "$sub -> $sub_result" >> "$output_file"
            fi
        done
        if [[ -n "$found_subs" ]]; then
            peas_add_finding "$host" "$port" "dns" "subdomain" "info" observed                 "Subdomains enumerated" "$found_subs" "dig"                 "Review exposed subdomains"
        fi
    fi

    peas_add_finding "$host" "$port" "dns" "info" "info" observed         "DNS Service" "Port $port/udp" "port" "Verify DNS configuration"
}
