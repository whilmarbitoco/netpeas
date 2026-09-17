#!/usr/bin/env bash
#
# NetPEAS — modules/dns.sh
# DNS service enumeration.
#

[[ -n "${_NETPEAS_MODULE_DNS_LOADED:-}" ]] && return 0
readonly _NETPEAS_MODULE_DNS_LOADED=1


dns_module() {
    local host="$1"
    local port="$2"
    local state_dir="$3"

    local output_file="${state_dir}/dns_${host}_${port}.txt"
    : > "$output_file"

    peas_info "DNS — $host:$port"

    if ! peas_has_tool dig; then
        peas_warn "dig not available; skipping DNS enumeration"
        return 1
    fi

    # Zone transfer attempt
    local axfr
    axfr="$(peas_exec_silent 10 dig @"$host" "$host" AXFR +time=5 +tries=1 2>/dev/null || echo "")"
    echo "$axfr" > "$output_file"

    if echo "$axfr" | grep -q "XFR"; then
        peas_finding "high" "DNS zone transfer allowed"
        peas_add_finding "$host" "$port" "dns" "config" "high" "confirmed" \
            "DNS zone transfer" "AXFR request returned records" "dig" \
            "Restrict zone transfer to authorized hosts"
    fi

    # Common records lookup
    local records
    records="$(peas_exec_silent 5 dig @"$host" "$host" ANY +short 2>/dev/null || echo "")"
    [[ -n "$records" ]] && peas_detail "Records: $records"
}

