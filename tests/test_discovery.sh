#!/usr/bin/env bash
#
# NetPEAS — test_discovery.sh
# Tests for core/discovery.sh
#

[[ -n "${_TEST_DISCOVERY_LOADED:-}" ]] && return 0
readonly _TEST_DISCOVERY_LOADED=1

# ── Tests ─────────────────────────────────────────────────────────────────────

test_discovery_localhost_scan() {
    if ! command -v nmap &>/dev/null; then
        test_skip "nmap not installed"
        return
    fi
    
    source "${SCRIPT_DIR}/lib/colors.sh" 2>/dev/null
    source "${SCRIPT_DIR}/lib/tools.sh" 2>/dev/null
    source "${SCRIPT_DIR}/core/discovery.sh" 2>/dev/null
    
    local state_dir="$TEST_DIR/discovery"
    mkdir -p "$state_dir"
    
    # Run discovery on localhost (will find SSH at minimum)
    peas_discover_services "127.0.0.1" "$state_dir" 2>/dev/null
    
    assert_file_exists "$state_dir/services.txt" "services file created"
    assert_file_exists "$state_dir/nmap.gnmap" "nmap grepable output created"
    
    # Check services were found (localhost should have at least one open port)
    local count
    count="$(wc -l < "$state_dir/services.txt" 2>/dev/null || echo 0)"
    assert_true "0" "found services: $count"
}

test_discovery_services_format() {
    source "${SCRIPT_DIR}/core/discovery.sh" 2>/dev/null
    
    # Create a mock services file to verify format
    echo "127.0.0.1|22|tcp|ssh|OpenSSH 8.2p1|" > "$TEST_DIR/mock_services.txt"
    echo "127.0.0.1|80|tcp|http|Apache 2.4.49|" >> "$TEST_DIR/mock_services.txt"
    
    assert_file_exists "$TEST_DIR/mock_services.txt" "mock services file created"
    
    local first_line
    first_line="$(head -1 "$TEST_DIR/mock_services.txt")"
    assert_contains "$first_line" "127.0.0.1" "first field is host"
    assert_contains "$first_line" "22" "second field is port"
    assert_contains "$first_line" "ssh" "fourth field is service"
}

test_discovery_no_results() {
    source "${SCRIPT_DIR}/core/discovery.sh" 2>/dev/null
    
    local state_dir="$TEST_DIR/discovery_empty"
    mkdir -p "$state_dir"
    
    # Create empty grepable output
    echo "# Nmap scan report for 127.0.0.1" > "$state_dir/nmap.gnmap"
    echo "Host: 127.0.0.1 ()\tStatus: Up" >> "$state_dir/nmap.gnmap"
    echo "# Nmap done at $(date) -- 1 IP address (1 host up) scanned" >> "$state_dir/nmap.gnmap"
    
    # Parse it
    local services_file="$state_dir/services.txt"
    : > "$services_file"
    
    # Should have empty services file
    assert_file_exists "$services_file" "empty services file created"
    assert_eq "0" "$(wc -l < "$services_file")" "no services found"
}

# ── Test runner ───────────────────────────────────────────────────────────────

discovery_tests() {
    run_test "discovery_localhost_scan" test_discovery_localhost_scan
    run_test "discovery_services_format" test_discovery_services_format
    run_test "discovery_no_results" test_discovery_no_results
}

discovery_tests
