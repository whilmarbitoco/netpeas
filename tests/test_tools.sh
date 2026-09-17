#!/usr/bin/env bash
#
# NetPEAS — test_tools.sh
# Tests for lib/tools.sh
#

[[ -n "${_TEST_TOOLS_LOADED:-}" ]] && return 0
readonly _TEST_TOOLS_LOADED=1

# ── Tests ─────────────────────────────────────────────────────────────────────

test_tools_detect_required() {
    source "${SCRIPT_DIR}/lib/tools.sh" 2>/dev/null
    if command -v nmap &>/dev/null; then
        assert_true "0" "nmap should be detected"
    else
        test_skip "nmap not installed"
    fi
}

test_tools_has_tool() {
    source "${SCRIPT_DIR}/lib/tools.sh" 2>/dev/null
    if command -v curl &>/dev/null; then
        if peas_has_tool curl; then
            assert_true "0" "peas_has_tool finds curl"
        else
            assert_true "1" "peas_has_tool should find curl"
        fi
    else
        test_skip "curl not installed"
    fi
}

test_tools_missing_tool() {
    source "${SCRIPT_DIR}/lib/tools.sh" 2>/dev/null
    if ! command -v enum4linux-ng &>/dev/null; then
        if ! peas_has_tool enum4linux-ng; then
            assert_true "0" "missing tool not found"
        fi
    else
        test_skip "enum4linux-ng is installed"
    fi
}

test_tools_extract_version_basic() {
    source "${SCRIPT_DIR}/lib/tools.sh" 2>/dev/null
    local ver
    ver="$(peas_extract_version "Apache 2.4.49")"
    assert_eq "2.4.49" "$ver" "extract Apache version"
}

test_tools_extract_version_ssh() {
    source "${SCRIPT_DIR}/lib/tools.sh" 2>/dev/null
    local ver
    ver="$(peas_extract_version "SSH-2.0-OpenSSH_8.2p1")"
    assert_eq "8.2" "$ver" "extract SSH version"
}

test_tools_extract_version_no_version() {
    source "${SCRIPT_DIR}/lib/tools.sh" 2>/dev/null
    local ver
    ver="$(peas_extract_version "Unknown Service")"
    assert_eq "" "$ver" "no version found"
}

# ── Test runner ───────────────────────────────────────────────────────────────

tools_tests() {
    run_test "tools_detect_required" test_tools_detect_required
    run_test "tools_has_tool" test_tools_has_tool
    run_test "tools_missing_tool" test_tools_missing_tool
    run_test "tools_extract_version_basic" test_tools_extract_version_basic
    run_test "tools_extract_version_ssh" test_tools_extract_version_ssh
    run_test "tools_extract_version_no_version" test_tools_extract_version_no_version
}

tools_tests
