#!/usr/bin/env bash
#
# NetPEAS — modules/ssh.sh
# SSH service enumeration.
#

[[ -n "${_NETPEAS_MODULE_SSH_LOADED:-}" ]] && return 0
readonly _NETPEAS_MODULE_SSH_LOADED=1


ssh_module() {
    local host="$1"
    local port="$2"
    local state_dir="$3"

    local output_file="${state_dir}/ssh_${host}_${port}.txt"
    : > "$output_file"

    peas_info "SSH — $host:$port"

    # Banner grab
    local banner
    banner="$(peas_exec_silent 5 bash -c "echo | timeout 5 nc -w3 $host $port 2>/dev/null" || echo "")"
    if [[ -z "$banner" ]]; then
        banner="$(peas_exec_silent 5 ssh -o ConnectTimeout=3 -o BatchMode=yes -o StrictHostKeyChecking=no "$host" -p "$port" 2>&1 | head -5)"
    fi
    echo "$banner" > "$output_file"

    local version="$(echo "$banner" | grep -oP 'SSH-\d+\.\d+-\K[^\s]+' | head -1)"
    if [[ -z "$version" ]]; then
        version="$(peas_extract_version "$banner")"
    fi

    local title="SSH Service"
    [[ -n "$version" ]] && title="SSH — $version"

    peas_add_finding "$host" "$port" "ssh" "info" "info" "observed" \
        "$title" "Banner: ${banner:0:100}" "nc/ssh" "Check for weak configurations"

    if [[ -n "$version" ]]; then
        peas_searchsploit "$version" 3 2>/dev/null >> "$output_file" || true
    fi
}

