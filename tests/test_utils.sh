#!/usr/bin/env bash
#
# NetPEAS — test_utils.sh
# Tests for lib/utils.sh
#

[[ -n "${_TEST_UTILS_LOADED:-}" ]] && return 0
readonly _TEST_UTILS_LOADED=1

# ── Tests ─────────────────────────────────────────────────────────────────────

test_utils_validate_ip_valid() {
    source "${SCRIPT_DIR}/lib/utils.sh" 2>/dev/null
    if peas_validate_ip "10.10.10.24"; then
        assert_true "0" "valid IP accepted"
    else
        assert_true "1" "valid IP should be accepted"
    fi
}

test_utils_validate_ip_invalid() {
    source "${SCRIPT_DIR}/lib/utils.sh" 2>/dev/null
    if peas_validate_ip "not-an-ip"; then
        assert_true "1" "invalid IP should be rejected"
    else
        assert_true "0" "invalid IP rejected"
    fi
}

test_utils_validate_cidr_valid() {
    source "${SCRIPT_DIR}/lib/utils.sh" 2>/dev/null
    if peas_validate_cidr "10.10.10.0/24"; then
        assert_true "0" "valid CIDR accepted"
    else
        assert_true "1" "valid CIDR should be accepted"
    fi
}

test_utils_validate_cidr_invalid() {
    source "${SCRIPT_DIR}/lib/utils.sh" 2>/dev/null
    if peas_validate_cidr "not-cidr"; then
        assert_true "1" "invalid CIDR should be rejected"
    else
        assert_true "0" "invalid CIDR rejected"
    fi
}

test_utils_validate_host_valid() {
    source "${SCRIPT_DIR}/lib/utils.sh" 2>/dev/null
    if peas_validate_host "hostname.local"; then
        assert_true "0" "valid hostname accepted"
    else
        assert_true "1" "valid hostname should be accepted"
    fi
}

test_utils_validate_host_invalid() {
    source "${SCRIPT_DIR}/lib/utils.sh" 2>/dev/null
    if peas_validate_host "invalid host!"; then
        assert_true "1" "invalid hostname should be rejected"
    else
        assert_true "0" "invalid hostname rejected"
    fi
}

test_utils_mktemp_dir() {
    source "${SCRIPT_DIR}/lib/utils.sh" 2>/dev/null
    local tmpdir
    tmpdir="$(peas_mktemp_dir)"
    assert_dir_exists "$tmpdir" "temp dir created"
    assert_contains "$tmpdir" "netpeas" "temp dir has netpeas prefix"
    rm -rf "$tmpdir"
}

test_utils_cleanup() {
    source "${SCRIPT_DIR}/lib/utils.sh" 2>/dev/null
    local tmpdir
    tmpdir="$(peas_mktemp_dir)"
    peas_cleanup "$tmpdir"
    if [[ -d "$tmpdir" ]]; then
        assert_true "1" "temp dir should be removed"
    else
        assert_true "0" "temp dir removed"
    fi
}

test_utils_truncate_short() {
    source "${SCRIPT_DIR}/lib/utils.sh" 2>/dev/null
    local result
    result="$(peas_truncate "short" 80)"
    assert_eq "short" "$result" "short string not truncated"
}

test_utils_truncate_long() {
    source "${SCRIPT_DIR}/lib/utils.sh" 2>/dev/null
    local long_str="This is a very long string that should be truncated because it exceeds the maximum length"
    local result
    result="$(peas_truncate "$long_str" 20)"
    assert_contains "$result" "..." "long string truncated with ellipsis"
}

test_utils_extract_basic() {
    source "${SCRIPT_DIR}/lib/utils.sh" 2>/dev/null
    local result
    result="$(peas_extract "Apache/2.4.49" '(\d+\.\d+\.\d+)')"
    assert_eq "2.4.49" "$result" "extract version from string"
}

# ── Test runner ───────────────────────────────────────────────────────────────

utils_tests() {
    run_test "utils_validate_ip_valid" test_utils_validate_ip_valid
    run_test "utils_validate_ip_invalid" test_utils_validate_ip_invalid
    run_test "utils_validate_cidr_valid" test_utils_validate_cidr_valid
    run_test "utils_validate_cidr_invalid" test_utils_validate_cidr_invalid
    run_test "utils_validate_host_valid" test_utils_validate_host_valid
    run_test "utils_validate_host_invalid" test_utils_validate_host_invalid
    run_test "utils_mktemp_dir" test_utils_mktemp_dir
    run_test "utils_cleanup" test_utils_cleanup
    run_test "utils_truncate_short" test_utils_truncate_short
    run_test "utils_truncate_long" test_utils_truncate_long
    run_test "utils_extract_basic" test_utils_extract_basic
}

utils_tests
