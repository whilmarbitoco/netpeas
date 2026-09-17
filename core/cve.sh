#!/usr/bin/env bash

declare -A CVE_CACHE=()

peas_cve_lookup() {
    local product="$1"
    local version="$2"

    [[ -z "$product" || -z "$version" ]] && return 1

    local key="${product}:${version}"
    if [[ -n "${CVE_CACHE[$key]:-}" ]]; then
        echo "${CVE_CACHE[$key]}"
        return 0
    fi

    local results
    results="$(peas_searchsploit "$product $version" 5 2>/dev/null || echo "")"

    if [[ -n "$results" ]]; then
        CVE_CACHE["$key"]="$results"
        echo "$results"
        return 0
    fi
    return 1
}
