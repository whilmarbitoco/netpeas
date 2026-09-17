#!/usr/bin/env bash

STATE_FILE=""
FINDINGS_FILE=""

peas_state_init() {
    local state_dir="$1"
    local scan_id="${2:-$(date +%s)}"
    STATE_FILE="${state_dir}/${scan_id}.state"
    FINDINGS_FILE="${state_dir}/${scan_id}.findings"
    cat > "$STATE_FILE" << STATE_EOF
SCAN_ID=${scan_id}
START_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)
MODE=$(peas_get_mode)
TARGETS=$(IFS=,; echo "${TARGETS[*]}")
STATUS=running
STATE_EOF
    touch "$FINDINGS_FILE"
}

peas_state_update() {
    local key="$1" value="$2"
    [[ -z "$STATE_FILE" ]] && return
    if grep -q "^${key}=" "$STATE_FILE" 2>/dev/null; then
        sed -i "s/^${key}=.*/${key}=${value}/" "$STATE_FILE"
    else
        echo "${key}=${value}" >> "$STATE_FILE"
    fi
}

peas_state_mark_completed() {
    peas_state_update "STATUS" "completed"
    peas_state_update "END_TIME" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}

peas_state_mark_failed() {
    peas_state_update "STATUS" "failed"
    peas_state_update "END_TIME" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}

peas_state_add_completed_target() {
    local target="$1"
    [[ -z "$STATE_FILE" ]] && return
    echo "COMPLETED_TARGET=${target}" >> "$STATE_FILE"
}

peas_state_is_target_completed() {
    local target="$1"
    [[ -z "$STATE_FILE" ]] && return 1
    grep -q "COMPLETED_TARGET=${target}" "$STATE_FILE" 2>/dev/null
}

peas_state_save_finding() {
    local finding="$1"
    [[ -z "$FINDINGS_FILE" ]] && return
    echo "$finding" >> "$FINDINGS_FILE"
}

peas_state_load_findings() {
    [[ -z "$FINDINGS_FILE" || ! -f "$FINDINGS_FILE" ]] && return 1
    cat "$FINDINGS_FILE"
}

peas_state_resume_targets() {
    local state_file="$1"
    [[ ! -f "$state_file" ]] && return 1
    local -a all_targets=()
    local -a completed_targets=()
    while IFS='=' read -r key value; do
        case "$key" in
            TARGETS) IFS=',' read -ra all_targets <<< "$value" ;;
            COMPLETED_TARGET) completed_targets+=("$value") ;;
        esac
    done < "$state_file"
    local -a remaining=()
    for t in "${all_targets[@]}"; do
        local done=false
        for c in "${completed_targets[@]}"; do
            [[ "$t" == "$c" ]] && done=true && break
        done
        [[ "$done" == "false" ]] && remaining+=("$t")
    done
    echo "${remaining[@]}"
}
