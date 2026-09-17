#!/usr/bin/env bash
#
# NetPEAS — core/findings.sh
# Finding collection, classification, and rendering.
#

[[ -n "${_NETPEAS_FINDINGS_LOADED:-}" ]] && return 0
readonly _NETPEAS_FINDINGS_LOADED=1

set -Eeuo pipefail

# ── Finding store ─────────────────────────────────────────────────────────────

# Finding format (pipe-delimited for parsing):
# host|port|service|type|severity|confidence|title|evidence|source|recommendation
declare -a FINDINGS=()

# ── Create finding ────────────────────────────────────────────────────────────

peas_add_finding() {
    local host="$1"
    local port="$2"
    local service="$3"
    local type="$4"
    local severity="$5"
    local confidence="$6"
    local title="$7"
    local evidence="$8"
    local source="${9:-netpeas}"
    local recommendation="${10:-}"

    # Escape pipes in fields
    title="${title//|/\\|}"
    evidence="${evidence//|/\\|}"
    recommendation="${recommendation//|/\\|}"

    FINDINGS+=("${host}|${port}|${service}|${type}|${severity}|${confidence}|${title}|${evidence}|${source}|${recommendation}")
}

# ── Render findings ───────────────────────────────────────────────────────────

peas_render_findings() {
    if [[ "$(peas_get_output_format)" == "json" ]]; then
        peas_render_findings_json
    else
        peas_render_findings_text
    fi
}

# ── Text renderer ─────────────────────────────────────────────────────────────

peas_render_findings_text() {
    if [[ ${#FINDINGS[@]} -eq 0 ]]; then
        peas_info "No significant findings"
        return
    fi

    peas_section "Findings"

    for finding in "${FINDINGS[@]}"; do
        IFS='|' read -r host port service type severity confidence title evidence source recommendation <<< "$finding"

        peas_section "$host:$port — $title"
        peas_detail "Service: $service"
        peas_detail "Severity: $severity | Confidence: $confidence"
        [[ -n "$evidence" ]] && peas_detail "Evidence: $evidence"
        [[ -n "$recommendation" ]] && peas_detail "Recommendation: $recommendation"
        echo ""
    done
}

# ── JSON renderer ─────────────────────────────────────────────────────────────

peas_render_findings_json() {
    echo "{"
    echo "  \"scan_id\": \"$(date +%s)\","
    echo "  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
    echo "  \"mode\": \"$(peas_get_mode)\","
    echo "  \"total_findings\": ${#FINDINGS[@]},"
    echo "  \"findings\": ["

    local count=0
    for finding in "${FINDINGS[@]}"; do
        ((count++))
        IFS='|' read -r host port service type severity confidence title evidence source recommendation <<< "$finding"

        echo "    {"
        echo "      \"host\": \"$host\","
        echo "      \"port\": \"$port\","
        echo "      \"service\": \"$service\","
        echo "      \"type\": \"$type\","
        echo "      \"severity\": \"$severity\","
        echo "      \"confidence\": \"$confidence\","
        echo "      \"title\": \"$title\","
        echo "      \"evidence\": \"$evidence\","
        echo "      \"source\": \"$source\","
        echo "      \"recommendation\": \"$recommendation\""
        echo -n "    }"
        [[ $count -lt ${#FINDINGS[@]} ]] && echo "," || echo ""
    done

    echo "  ]"
    echo "}"
}

# ── Summary ───────────────────────────────────────────────────────────────────

peas_render_summary() {
    local total_hosts="$1"
    local total_ports="$2"

    peas_section "Summary"
    peas_detail "Hosts scanned: $total_hosts"
    ports="Ports discovered: $total_ports"
    peas_detail "$ports"
    peas_detail "Findings: ${#FINDINGS[@]}"
}
