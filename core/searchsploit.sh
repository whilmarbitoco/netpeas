#!/usr/bin/env bash

peas_searchsploit() {
    local query="$1"
    local max="${2:-5}"

    if ! peas_has_tool searchsploit; then
        peas_debug "SearchSploit not available"
        return 1
    fi

    local results
    results="$(searchsploit --colour "$query" 2>/dev/null | head -$((max + 3)) | tail -n +3 | head -"$max")"

    if [[ -n "$results" ]]; then
        echo "$results"
        return 0
    fi
    return 1
}
