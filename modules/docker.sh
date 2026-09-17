#!/usr/bin/env bash
#
# NetPEAS — modules/docker.sh
# Docker API enumeration
#

docker_module() {
    local host="$1"
    local port="$2"
    local state_dir="$3"

    local output_file="${state_dir}/docker_${host}_${port}.txt"
    : > "$output_file"

    peas_info "Docker API — $host:$port"

    # ── Container List (Unauthenticated) ───────────────────────────────
    local containers
    containers="$(peas_exec_silent 10 curl -s --connect-timeout 5 "http://${host}:${port}/containers/json?all=true" 2>/dev/null || echo "")"
    echo "$containers" > "$output_file"

    if echo "$containers" | grep -q '"Id"'; then
        local container_count="$(echo "$containers" | grep -o '"Id"' | wc -l)"
        peas_add_finding "$host" "$port" "docker" "auth" "critical" "confirmed" \
            "Unauthenticated Docker API" "Found $container_count containers" "curl" \
            "Enable Docker authentication (TLS + certificates)"

        # Check for sensitive container names
        if echo "$containers" | grep -qi "prod\|prod-\|production\|db-\|mysql\|postgres"; then
            peas_add_finding "$host" "$port" "docker" "info" "high" "observed" \
                "Production containers exposed" "Prod containers visible via API" "curl" \
                "Enable Docker authentication"
        fi
    fi

    # ── Docker Version ─────────────────────────────────────────────────
    local version
    version="$(peas_exec_silent 10 curl -s --connect-timeout 5 "http://${host}:${port}/version" 2>/dev/null || echo "")"
    if [[ -n "$version" ]]; then
        echo "$version" >> "$output_file"
        local docker_ver="$(echo "$version" | grep -oP '"Version":"[^"]*"' | head -1)"
        peas_add_finding "$host" "$port" "docker" "info" "medium" "confirmed" \
            "Docker API exposed" "Version: $docker_ver" "curl" \
            "Restrict Docker API access"
    fi

    # ── System Info ────────────────────────────────────────────────────
    local info
    info="$(peas_exec_silent 10 curl -s --connect-timeout 5 "http://${host}:${port}/info" 2>/dev/null || echo "")"
    if [[ -n "$info" ]]; then
        echo "$info" >> "$output_file"

        # Check for running containers count
        local running="$(echo "$info" | grep -oP '"ContainersRunning":\d+' | head -1)"
        [[ -n "$running" ]] && peas_detail "Running: $running"

        # Check for root user in containers
        if echo "$info" | grep -qi "root\|privileged"; then
            peas_add_finding "$host" "$port" "docker" "config" "high" "observed" \
                "Docker root/privileged mode detected" "Containers may run as root" "curl" \
                "Use non-root containers, drop capabilities"
        fi
    fi

    # ── Image List ─────────────────────────────────────────────────────
    local images
    images="$(peas_exec_silent 10 curl -s --connect-timeout 5 "http://${host}:${port}/images/json" 2>/dev/null || echo "")"
    if [[ -n "$images" ]]; then
        echo "$images" >> "$output_file"
        local img_count="$(echo "$images" | grep -o '"Id"' | wc -l)"
        if [[ $img_count -gt 0 ]]; then
            peas_add_finding "$host" "$port" "docker" "info" "medium" "observed" \
                "Docker images exposed" "Found $img_count images" "curl" \
                "Enable Docker authentication"
        fi
    fi

    # ── Check for sensitive mounts ─────────────────────────────────────
    local mounts
    mounts="$(peas_exec_silent 10 curl -s --connect-timeout 5 "http://${host}:${port}/containers/json?all=true" 2>/dev/null || echo "")"
    if echo "$mounts" | grep -qi "Mounts.*Source.*\(/etc\|/root\|/var\|/home\|/opt\|/\)"; then
        peas_add_finding "$host" "$port" "docker" "mount" "high" "observed" \
            "Sensitive host paths mounted" "Host directories mounted in containers" "curl" \
            "Review container mount points for host access"
    fi

    # ── Intelligence ────────────────────────────────────────────────────
    local exploit_results
    exploit_results="$(peas_searchsploit "Docker" 3 2>/dev/null || echo "")"
    if [[ -n "$exploit_results" ]]; then
        echo "$exploit_results" >> "$output_file"
        peas_add_finding "$host" "$port" "docker" "cve" "medium" "likely" \
            "Known Docker exploits" "$exploit_results" "searchsploit" \
            "Review and patch"
    fi

    return 0
}