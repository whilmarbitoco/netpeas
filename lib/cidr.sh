#!/usr/bin/env bash

# CIDR / Range Expansion
peas_expand_targets() {
    local -a expanded=()
    for target in "$@"; do
        if [[ "$target" =~ ^([0-9]+\.[0-9]+\.[0-9]+)\.([0-9]+)-([0-9]+)$ ]]; then
            local prefix="${BASH_REMATCH[1]}"
            local start="${BASH_REMATCH[2]}"
            local end="${BASH_REMATCH[3]}"
            for ((i=start; i<=end; i++)); do
                expanded+=("${prefix}.${i}")
            done
        elif [[ "$target" =~ ^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/([0-9]+)$ ]]; then
            expanded+=("$target")
        else
            expanded+=("$target")
        fi
    done
    echo "${expanded[@]}"
}

peas_validate_target() {
    local target="$1"
    [[ "$target" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && return 0
    [[ "$target" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$ ]] && return 0
    [[ "$target" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+-[0-9]+$ ]] && return 0
    [[ "$target" =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]*$ ]] && return 0
    return 1
}
