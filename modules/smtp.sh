#!/usr/bin/env bash
[[ -n "${_NETPEAS_MODULE_SMTP_LOADED:-}" ]] && return 0
readonly _NETPEAS_MODULE_SMTP_LOADED=1

smtp_module() {
    local host="$1"
    local port="$2"
    local state_dir="$3"

    local output_file="${state_dir}/smtp_${host}_${port}.txt"
    : > "$output_file"

    peas_info "SMTP — $host:$port"

    # ── Banner Grab ──────────────────────────────────────────────────────────
    local banner=""
    if peas_has_tool nc; then
        banner="$(peas_exec_silent 5 bash -c "echo | timeout 5 nc -w3 $host $port 2>/dev/null" || echo "")"
    fi
    if [[ -z "$banner" ]]; then
        peas_debug "Cannot reach SMTP on $host:$port"
        return 0
    fi
    echo "$banner" > "$output_file"

    local version="$(peas_extract_version "$banner")"
    local title="SMTP Service"
    [[ -n "$version" ]] && title="SMTP — $version"

    peas_add_finding "$host" "$port" "smtp" "info" "info" observed         "$title" "Banner: ${banner:0:100}" "nc" "Review SMTP configuration"

    # ── VRFY Test ────────────────────────────────────────────────────────────
    if peas_has_tool nc; then
        local vrfy_result
        vrfy_result="$(peas_exec_silent 5 bash -c "echo VRFY root | timeout 5 nc -w3 $host $port 2>/dev/null" || echo "")"
        if echo "$vrfy_result" | grep -q "250"; then
            peas_add_finding "$host" "$port" "smtp" "vrfy" "medium" observed                 "VRFY command allows user enumeration" "$vrfy_result" "nc"                 "Disable VRFY command"
        fi
        echo "VRFY: $vrfy_result" >> "$output_file"
    fi

    # ── EXPN Test ────────────────────────────────────────────────────────────
    if peas_has_tool nc; then
        local expn_result
        expn_result="$(peas_exec_silent 5 bash -c "echo EXPN postmaster | timeout 5 nc -w3 $host $port 2>/dev/null" || echo "")"
        if echo "$expn_result" | grep -q "250"; then
            peas_add_finding "$host" "$port" "smtp" "expn" "medium" observed                 "EXPN command allows mailing list expansion" "$expn_result" "nc"                 "Disable EXPN command"
        fi
        echo "EXPN: $expn_result" >> "$output_file"
    fi

    # ── STARTTLS Check ───────────────────────────────────────────────────────
    if peas_has_tool nc; then
        local starttls_result
        starttls_result="$(peas_exec_silent 5 bash -c "echo STARTTLS | timeout 5 nc -w3 $host $port 2>/dev/null" || echo "")"
        if [[ -n "$starttls_result" ]]; then
            echo "STARTTLS: $starttls_result" >> "$output_file"
        fi
    fi

    # ── Open Relay Test ──────────────────────────────────────────────────────
    if peas_has_tool nc; then
        local relay_result
        relay_result="$(peas_exec_silent 5 bash -c "EHLO test.com\nMAIL FROM: <test@test.com>\nRCPT TO: <admin@test.com>\nQUIT | timeout 5 nc -w3 $host $port 2>/dev/null" || echo "")"
        if echo "$relay_result" | grep -q "250.*250.*250"; then
            peas_add_finding "$host" "$port" "smtp" "relay" "high" observed                 "Possible open relay" "$relay_result" "nc"                 "Configure SMTP authentication"
        fi
        echo "Relay test: $relay_result" >> "$output_file"
    fi
}
