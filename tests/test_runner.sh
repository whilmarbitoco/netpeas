#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

TESTS_TOTAL=0; TESTS_PASSED=0; TESTS_FAILED=0; TESTS_SKIPPED=0
CURRENT_TEST=""

assert_eq() { [[ "$1" == "$2" ]] || { echo -e "${RED}  ✗ FAIL: ${3}${NC} (Expected='$1' Actual='$2')"; return 1; }; }
assert_contains() { echo "$1" | grep -q "$2" || { echo -e "${RED}  ✗ FAIL: ${3}${NC} (Needle='$2')"; return 1; }; }
assert_not_empty() { [[ -n "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC}"; return 1; }; }
assert_empty() { [[ -z "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Got='$1')"; return 1; }; }

test_start() { CURRENT_TEST="$1"; ((TESTS_TOTAL++)); echo -e "${YELLOW}  ▶ $1${NC}"; }
test_pass() { ((TESTS_PASSED++)); echo -e "${GREEN}  ✓ $CURRENT_TEST${NC}"; }
test_fail() { ((TESTS_FAILED++)); }
test_skip() { ((TESTS_SKIPPED++)); echo -e "  ⏭ $CURRENT_TEST ($1)"; }

run_test() {
    local name="$1" fn="$2"
    test_start "$name"
    if $fn; then test_pass; else test_fail; fi
}

setup() { TEST_DIR="$(mktemp -d -t netpeas.XXXXXX)"; export TEST_DIR; }
teardown() { [[ -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"; }

run_all_tests() {
    echo ""; echo "╔══════════════════════════════════════════╗"
    echo "║        NetPEAS Test Suite v1.0          ║"
    echo "╚══════════════════════════════════════════╝"; echo ""

    setup
    for tf in "${TESTS_DIR}"/test_*.sh; do
        [[ "$(basename "$tf")" == "test_runner.sh" ]] && continue
        echo ""; echo "━━━ $(basename "$tf" .sh) ━━━"
        source "$tf"
        local runner="${tf##*_}"; runner="${runner%.sh}_tests"
        "$(basename "$tf" .sh)_tests" 2>/dev/null || true
    done
    teardown

    echo ""; echo "══════════════════════════════════════════"
    echo "  Total: $TESTS_TOTAL"; echo -e "  ${GREEN}Passed: $TESTS_PASSED${NC}"
    [[ $TESTS_FAILED -gt 0 ]] && echo -e "  ${RED}Failed: $TESTS_FAILED${NC}"
    [[ $TESTS_SKIPPED -gt 0 ]] && echo "  Skipped: $TESTS_SKIPPED"
    echo "══════════════════════════════════════════"
    [[ $TESTS_FAILED -eq 0 ]]
}

run_all_tests
