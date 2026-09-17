#!/usr/bin/env bash
#
# NetPEAS — modules/smtp.sh
# SMTP service enumeration.
#

[[ -n "${_NETPEAS_MODULE_SMTP_LOADED:-}" ]] && return 0
readonly _NETPEAS_MODULE_SMTP_LOADED=1


smtp_module() {
    local host="$1"
    local port="$2"
    local state_dir="$3"

    local output_file="${state_dir}/smtp_${host}_${port}.txt"
    : > "$output_file"

    peas_info "SMTP — $host:$port"

    if ! peas_has_tool nc; then
        peas_warn "nc not available; skipping SMTP"
        return 1
    fi

    # Banner grab
    local banner
    banner="$(peas_exec_silent 5 bash -c "echo | timeout 5 nc -w3 $host $port 2>/dev/null")"
    echo "$banner" > "$output_file"

    local version="$(echo "$banner" | grep -oP '\d+\.\d+\.\d+' | head -1)"
    local title="SMTP Service"
    [[ -n "$version" ]] && title="SMTP — $version"

    peas_add_finding "$host" "$port" "smtp" "info" "info" "observed" \
        "$title" "Banner: ${banner:0:100}" "nc" "Check for open relay and user enumeration"

    # VRFY command test
    local vrfy_test
    vrfy_test="$(peas_exec_silent 5 bash -c "echo -e 'VRFY root\r\nQUIT' | timeout 5 nc -w3 $host $port 2>/dev/null")"
    if echo "$vrfy_test" | grep -q "250\|252"; then
        peas_finding "medium" "SMTP VRFY user enumeration enabled"
        peas_add_finding "$host" "$port" "smtp" "config" "medium" "confirmed" \
            "SMTP VRFY enabled" "Server responded to VRFY command" "nc" \
            "Disable VRFY command"
    fi
}

