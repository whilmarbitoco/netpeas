#!/usr/bin/env bash

declare -a FINDINGS=()

peas_add_finding() {
    local host="$1" port="$2" service="$3" type="$4" severity="$5" confidence="$6" title="$7" evidence="$8" source="$9" recommendation="${10}"
    FINDINGS+=("${host}|${port}|${service}|${type}|${severity}|${confidence}|${title}|${evidence}|${source}|${recommendation}")
}

peas_render_findings() {
    [[ "$(peas_get_output_format)" == "json" ]] && peas_render_findings_json || peas_render_findings_text
}

peas_render_findings_text() {
    if [[ ${#FINDINGS[@]} -eq 0 ]]; then peas_info "No significant findings"; return; fi
    peas_section "Findings"
    for finding in "${FINDINGS[@]}"; do
        IFS='|' read -r host port service type severity confidence title evidence source recommendation <<< "$finding"
        peas_section "$host:$port \u2014 $title"
        peas_detail "Service: $service"
        peas_detail "Severity: $severity | Confidence: $confidence"
        [[ -n "$evidence" ]] && peas_detail "Evidence: $evidence"
        [[ -n "$recommendation" ]] && peas_detail "Recommendation: $recommendation"
        echo ""
    done
}

peas_render_findings_json() {
    local json_file
    json_file="$(mktemp)"
    {
        echo '{'
        echo '  "scan_id": "'"$(date +%s)"'",'
        echo '  "timestamp": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'",'
        echo '  "mode": "'"$(peas_get_mode)"'",'
        echo '  "total_findings": '${#FINDINGS[@]}','
        echo '  "findings": ['

        local count=0
        for finding in "${FINDINGS[@]}"; do
            ((count++))
            IFS='|' read -r host port service type severity confidence title evidence source recommendation <<< "$finding"

            [[ $count -gt 1 ]] && echo "    ,"

            cat << FINDING_JSON
    {
      "host": "${host}",
      "port": "${port}",
      "service": "${service}",
      "type": "${type}",
      "severity": "${severity}",
      "confidence": "${confidence}",
      "title": "${title}",
      "evidence": "${evidence}",
      "source": "${source}",
      "recommendation": "${recommendation}"
    }
FINDING_JSON
        done

        echo '  ]'
        echo '}'
    } > "$json_file"

    cat "$json_file"
    rm -f "$json_file"
}

peas_render_summary() {
    local total_hosts="$1" total_ports="$2"
    peas_section "Summary"
    peas_detail "Hosts scanned: $total_hosts"
    peas_detail "Ports discovered: $total_ports"
    peas_detail "Findings: ${#FINDINGS[@]}"
}
