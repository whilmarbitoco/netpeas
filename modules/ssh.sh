#!/usr/bin/env bash

ssh_module() {
    local host="$1"
    local port="$2"
    local state_dir="$3"

    local output_file="${state_dir}/ssh_${host}_${port}.txt"
    : > "$output_file"

    peas_info "SSH — $host:$port"

    # ── Banner Grab ──────────────────────────────────────────────────────────
    local banner=""
    if peas_has_tool nc; then
        banner="$(peas_exec_silent 5 bash -c "echo | timeout 5 nc -w3 $host $port 2>/dev/null" || echo "")"
    fi
    if [[ -z "$banner" ]] && peas_has_tool ssh; then
        banner="$(peas_exec_silent 5 ssh -o ConnectTimeout=3 -o BatchMode=yes -o StrictHostKeyChecking=no "$host" -p "$port" 2>&1 | head -5 || echo "")"
    fi
    if [[ -z "$banner" ]]; then
        peas_debug "Cannot reach SSH on $host:$port"
        return 0
    fi
    echo "$banner" > "$output_file"

    local version="$(echo "$banner" | grep -oP 'SSH-\d+\.\d+-\K[^\s]+' | head -1)"
    [[ -z "$version" ]] && version="$(peas_extract_version "$banner")"

    local title="SSH Service"
    [[ -n "$version" ]] && title="SSH — $version"

    peas_add_finding "$host" "$port" "ssh" "info" "info" observed         "$title" "Banner: ${banner:0:100}" "nc/ssh" "Check for weak configurations"

    # ── Algorithm Enumeration ────────────────────────────────────────────────
    if peas_has_tool ssh; then
        local algos
        algos="$(peas_exec_silent 10 ssh -o ConnectTimeout=3 -o BatchMode=yes -o StrictHostKeyChecking=no -o KexAlgorithms="$k" -o Ciphers="$c" -o MACs="$m" "$host" -p "$port" 2>&1 | head -20 || echo "")"
        if [[ -n "$algos" ]]; then
            echo "$algos" >> "$output_file"
            # Check for weak algorithms
            local weak_algos=""
            echo "$algos" | grep -qi "cbc" && weak_algos="${weak_algos:+$weak_algos, }CBC mode"
            echo "$algos" | grep -qi "md5" && weak_algos="${weak_algos:+$weak_algos, }MD5"
            echo "$algos" | grep -qi "sha1" && weak_algos="${weak_algos:+$weak_algos, }SHA1"
            echo "$algos" | grep -qi "diffie-hellman-group1" && weak_algos="${weak_algos:+$weak_algos, }DH group1"
            if [[ -n "$weak_algos" ]]; then
                peas_add_finding "$host" "$port" "ssh" "algo" "medium" observed                     "Weak SSH algorithms" "$weak_algos" "ssh"                     "Disable weak algorithms"
            fi
        fi
    fi

    # ── Host Key Fingerprint ─────────────────────────────────────────────────
    if peas_has_tool ssh-keygen; then
        local key_output
        key_output="$(peas_exec_silent 10 bash -c "ssh-keyscan -t rsa,ecdsa,ed25519 -p $port $host 2>/dev/null" || echo "")"
        if [[ -n "$key_output" ]]; then
            local fingerprints="$(echo "$key_output" | while read line; do echo "$line" | ssh-keygen -lf - 2>/dev/null; done)"
            echo "$fingerprints" >> "$output_file"
        fi
    fi

    # ── Password Authentication Detection ────────────────────────────────────
    if peas_has_tool ssh; then
        local auth_methods
        auth_methods="$(peas_exec_silent 10 ssh -o ConnectTimeout=3 -o BatchMode=yes -o StrictHostKeyChecking=no "$host" -p "$port" 2>&1 | grep -i 'permission' || echo "")"
        if [[ -n "$auth_methods" ]]; then
            echo "$auth_methods" >> "$output_file"
        fi
    fi

    # ── Intelligence ─────────────────────────────────────────────────────────
    if [[ -n "$version" ]]; then
        local exploit_results="$(peas_searchsploit "OpenSSH $version" 5 2>/dev/null || echo "")"
        if [[ -n "$exploit_results" ]]; then
            peas_add_finding "$host" "$port" "ssh" "cve" "medium" likely                 "Known exploits for OpenSSH $version" "$exploit_results" "searchsploit"                 "Review and patch"
            echo "$exploit_results" >> "$output_file"
        fi
    fi
    return 0
}
