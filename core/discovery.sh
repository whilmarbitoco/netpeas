#!/usr/bin/env bash
#
# NetPEAS — core/discovery.sh
# Real nmap-based host discovery and service detection.
#

[[ -n "${_NETPEAS_DISCOVERY_LOADED:-}" ]] && return 0
readonly _NETPEAS_DISCOVERY_LOADED=1


peas_discover_services() {
    local target="$1"
    local state_dir="$2"

    peas_section "Discovery — $target"

    # Run nmap and parse results directly via grepable output
    local nmap_opts=(-sC -sV -T4 --open)
    case "$(peas_get_mode)" in
        fast)        nmap_opts=(-T4 -F --open) ;;
        aggressive)  nmap_opts=(-sC -sV -sT -A --version-intensity 5 -T3) ;;
    esac

    peas_info "Scanning with nmap..."

    local gnmap_file="${state_dir}/nmap.gnmap"
    local cmd_file="${state_dir}/nmap.cmd"

    timeout 300 nmap "${nmap_opts[@]}" -oG "$gnmap_file" -oN "$cmd_file" "$target" 2>/dev/null || true

    if [[ ! -s "$gnmap_file" ]]; then
        peas_error "No scan results"
        return 1
    fi

    # Parse grepable output: Host: IP (hostname)	Status: Up
    #   Ports: PORT/STATE/SERVICE/VERSION/EXTRA
    local services_file="${state_dir}/services.txt"
    : > "$services_file"

    local host="" ports_line=""
    while IFS= read -r line; do
        if [[ "$line" =~ Host:\ ([0-9.]+)\ +\((.*)\) ]]; then
            host="${BASH_REMATCH[1]}"
            # If hostname is empty, use IP
            [[ -z "${BASH_REMATCH[2]}" ]] || host="${BASH_REMATCH[1]} (${BASH_REMATCH[2]})"
        fi
        if [[ "$line" =~ Ports:\ (.+) ]]; then
            ports_line="${BASH_REMATCH[1]}"
            # Parse comma-separated ports
            IFS=',' read -ra PORTS <<< "$ports_line"
            for p in "${PORTS[@]}"; do
                p="$(echo "$p" | xargs)"  # trim
                # Format: 22/open/tcp//ssh//OpenSSH 8.2p1 Ubuntu 4ubuntu0.5/
                local port_num state service version
                port_num="$(echo "$p" | cut -d'/' -f1)"
                state="$(echo "$p" | cut -d'/' -f2)"
                service="$(echo "$p" | cut -d'/' -f5)"
                version="$(echo "$p" | cut -d'/' -f6- | sed 's/\/$//')"

                [[ "$state" != "open" ]] && continue
                [[ "$port_num" == "0" ]] && continue

                echo "${host}|${port_num}|tcp|${service}|${version:-}|" >> "$services_file"
                peas_info "Found: $host:$port_num $service"
            done
        fi
    done < "$gnmap_file"

    local count
    count="$(wc -l < "$services_file" 2>/dev/null || echo 0)"
    peas_info "Discovered $count open ports"
}
