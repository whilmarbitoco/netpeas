#!/usr/bin/env bash

declare -A CORRELATION_CACHE=()

peas_correlate_findings() {
    local host="$1" port="$2" service="$3"
    local key="${service}"
    if [[ -n "${CORRELATION_CACHE[$key]:-}" ]]; then
        CORRELATION_CACHE[$key]=$((CORRELATION_CACHE[$key] + 1))
    else
        CORRELATION_CACHE[$key]=1
    fi
    local count=${CORRELATION_CACHE[$key]}
    if [[ $count -gt 10 ]]; then
        echo "low"
    elif [[ $count -gt 5 ]]; then
        echo "medium"
    else
        echo "high"
    fi
}

peas_cross_reference_cve() {
    local cve_id="$1"
    local product="$2"
    local version="$3"
    local sources=0
    local confirmed=false
    if has_tool searchsploit; then
        searchsploit "$product" "$version" 2>/dev/null | grep -q "$cve_id" && ((sources++))
    fi
    if [[ $sources -ge 2 ]]; then
        confirmed=true
    fi
    echo "$confirmed"
}

peas_enrich_finding() {
    local host="$1" port="$2" service="$3" product="$4" version="$5"
    local enriched=""
    if [[ -f "/tmp/os_${host}" ]]; then
        local os=$(cat "/tmp/os_${host}" 2>/dev/null)
        enriched+="OS: ${os}; "
    fi
    if [[ -f "/tmp/banner_${host}_${port}" ]]; then
        local banner=$(cat "/tmp/banner_${host}_${port}" 2>/dev/null)
        enriched+="Banner: ${banner}; "
    fi
    if [[ "$service" == "https" || "$port" == "443" || "$port" == "8443" ]]; then
        if [[ -f "/tmp/ssl_${host}_${port}" ]]; then
            local ssl=$(cat "/tmp/ssl_${host}_${port}" 2>/dev/null)
            enriched+="SSL: ${ssl}; "
        fi
    fi
    echo "$enriched"
}
