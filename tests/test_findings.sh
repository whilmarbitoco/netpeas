#!/usr/bin/env bash
#
# NetPEAS — test_findings.sh
# Tests for core/findings.sh
#

[[ -n "${_TEST_FINDINGS_LOADED:-}" ]] && return 0
readonly _TEST_FINDINGS_LOADED=1

# ── Tests ─────────────────────────────────────────────────────────────────────

test_findings_add_finding() {
    source "${SCRIPT_DIR}/core/findings.sh" 2>/dev/null
    
    peas_add_finding "10.10.10.24" "80" "http" "info" "info" "high" \
        "Apache 2.4.49" "Server header" "curl" "Review config"
    
    assert_eq "1" "${#FINDINGS[@]}" "one finding added"
    assert_contains "${FINDINGS[0]}" "10.10.10.24" "finding contains host"
    assert_contains "${FINDINGS[0]}" "Apache 2.4.49" "finding contains title"
}

test_findings_multiple() {
    source "${SCRIPT_DIR}/core/findings.sh" 2>/dev/null
    
    peas_add_finding "10.10.10.24" "80" "http" "info" "info" "high" "Finding 1" "Evidence 1" "curl" "Rec 1"
    peas_add_finding "10.10.10.24" "443" "https" "info" "info" "medium" "Finding 2" "Evidence 2" "openssl" "Rec 2"
    peas_add_finding "10.10.10.24" "22" "ssh" "info" "info" "low" "Finding 3" "Evidence 3" "ssh" "Rec 3"
    
    assert_eq "3" "${#FINDINGS[@]}" "three findings added"
    assert_contains "${FINDINGS[1]}" "443" "second finding has port 443"
    assert_contains "${FINDINGS[2]}" "ssh" "third finding is SSH"
}

test_findings_pipe_escape() {
    source "${SCRIPT_DIR}/core/findings.sh" 2>/dev/null
    
    # Title with pipe character should be escaped
    peas_add_finding "10.10.10.24" "80" "http" "info" "info" "high" \
        "Title | with pipe" "Evidence" "curl" "Rec"
    
    assert_eq "1" "${#FINDINGS[@]}" "finding added"
    # Should not break parsing
    IFS='|' read -r host port service type severity confidence title evidence source recommendation <<< "${FINDINGS[0]}"
    assert_eq "Title | with pipe" "$title" "pipe in title preserved"
}

test_findings_empty() {
    source "${SCRIPT_DIR}/core/findings.sh" 2>/dev/null
    
    assert_eq "0" "${#FINDINGS[@]}" "no findings initially"
}

# ── Test runner ───────────────────────────────────────────────────────────────

findings_tests() {
    run_test "findings_add_finding" test_findings_add_finding
    run_test "findings_multiple" test_findings_multiple
    run_test "findings_pipe_escape" test_findings_pipe_escape
    run_test "findings_empty" test_findings_empty
}

findings_tests
