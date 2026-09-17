#!/usr/bin/env bash
#
# NetPEAS — core/discovery.sh
# Host discovery and port scanning using native tools.
#

[[ -n "${_NETPEAS_DISCOVERY_LOADED:-}" ]] && return 0
readonly _NETPEAS_DISCOVERY_LOADED=1

set -Eeuo pipefail

# ── Service discovery ─────────────────────────────────────────────────────────

peas_discover_services() {
    local target="$1"
    local state_dir="$2"

    peas_section "Discovery — $target"

    if peas_has_tool nmap; then
        peas_discover_nmap "$target" "$state_dir"
    else
        peas_error "No discovery tool available (nmap required)"
        return 1
    fi
}

# ── Nmap discovery ────────────────────────────────────────────────────────────

peas_discover_nmap() {
    local target="$1"
    local state_dir="$2"

    local nmap_cmd=(nmap)
    local output_file="${state_dir}/nmap_scan.xml"

    # Build command based on mode
    case "$(peas_get_mode)" in
        fast)
            nmap_cmd+=(-T4 -F --open)
            ;;
        aggressive)
            nmap_cmd+=(-sC -sV -sT -A --version-intensity 5 -T3)
            ;;
        *)
            nmap_cmd+=(-sC -sV -T4)
            ;;
    esac

    # Add output
    nmap_cmd+=(-oX "$output_file")

    # Add target
    nmap_cmd+=("$target")

    peas_info "Scanning with nmap..."
    peas_debug "Command: ${nmap_cmd[*]}"

    local exit_code=0
    timeout 300 "${nmap_cmd[@]}" || exit_code=$?

    if [[ "$exit_code" -ne 0 ]]; then
        peas_warn "Nmap scan returned non-zero: $exit_code"
    fi

    if [[ -f "$output_file" ]]; then
        peas_parse_nmap_xml "$output_file" "$state_dir"
    else
        peas_error "No scan output file produced"
        return 1
    fi
}

# ── Parse Nmap XML output ─────────────────────────────────────────────────────

peas_parse_nmap_xml() {
    local xml_file="$1"
    local state_dir="$2"

    local services_file="${state_dir}/services.txt"
    : > "$services_file"

    # Extract host and port info using basic grep/sed
    # Format: host|port|protocol|service|product|version
    while IFS= read -r line; do
        local host port_id protocol service product version
        host="$(echo "$line" | grep -oP 'addr="\K[^"]+')"
        port_id="$(echo "$line" | grep -oP 'portid="\K[^"]+')"
        protocol="$(echo "$line" | grep -oP 'protocol="\K[^"]+')"

        # Extract service info if available
        service="$(echo "$line" | grep -oP 'name="\K[^"]+' | head -1)"
        product="$(echo "$line" | grep -oP 'product="\K[^"]+')"
        version="$(echo "$line" | grep -oP 'version="\K[^"]+')"

        echo "${host:-unknown}|${port_id:-unknown}|${protocol:-tcp}|${service:-unknown}|${product:-}|${version:-}" >> "$services_file"

        if [[ -n "$port_id" && "$port_id" != "unknown" ]]; then
            peas_info "Found: $host/$port_id $service"
        fi
    done < "$xml_file"

    peas_info "Service registry saved to $services_file"
}

