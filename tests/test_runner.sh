#!/usr/bin/env bash
ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }
set -o pipefail
ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }

ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }

ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }

ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }
TESTS_TOTAL=0; TESTS_PASSED=0; TESTS_FAILED=0; TESTS_SKIPPED=0
ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }
CURRENT_TEST=""
ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }

ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }
assert_eq() { [[ "$1" == "$2" ]] || { echo -e "${RED}  ✗ FAIL: ${3}${NC} (Expected='$1' Actual='$2')"; return 1; }; }
ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }
assert_contains() { echo "$1" | grep -q "$2" || { echo -e "${RED}  ✗ FAIL: ${3}${NC} (Needle='$2')"; return 1; }; }
ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }
assert_not_empty() { [[ -n "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC}"; return 1; }; }
ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }
assert_empty() { [[ -z "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Got='$1')"; return 1; }; }
ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }

ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }
test_start() { CURRENT_TEST="$1"; ((TESTS_TOTAL++)); echo -e "${YELLOW}  ▶ $1${NC}"; }
ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }
test_pass() { ((TESTS_PASSED++)); echo -e "${GREEN}  ✓ $CURRENT_TEST${NC}"; }
ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }
test_fail() { ((TESTS_FAILED++)); }
ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }
test_skip() { ((TESTS_SKIPPED++)); echo -e "  ⏭ $CURRENT_TEST ($1)"; }
ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }

ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }
run_test() {
ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }
    local name="$1" fn="$2"
ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }
    test_start "$name"
ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }
    if $fn; then test_pass; else test_fail; fi
ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }
}
ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }

ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }
setup() { TEST_DIR="$(mktemp -d -t netpeas.XXXXXX)"; export TEST_DIR; }
ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }
teardown() { [[ -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"; }
ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }

ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }
run_all_tests() {
ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }
    echo ""; echo "╔══════════════════════════════════════════╗"
ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }
    echo "║        NetPEAS Test Suite v1.0          ║"
ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }
    echo "╚══════════════════════════════════════════╝"; echo ""
ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }

ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }
    setup
ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }
    for tf in "${TESTS_DIR}"/test_*.sh; do
ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }
        [[ "$(basename "$tf")" == "test_runner.sh" ]] && continue
ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }
        echo ""; echo "━━━ $(basename "$tf" .sh) ━━━"
ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }
        source "$tf"
ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }
        local runner="${tf##*_}"; runner="${runner%.sh}_tests"
ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }
        "$(basename "$tf" .sh)_tests" 2>/dev/null || true
ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }
    done
ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }
    teardown
ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }

ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }
    echo ""; echo "══════════════════════════════════════════"
ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }
    echo "  Total: $TESTS_TOTAL"; echo -e "  ${GREEN}Passed: $TESTS_PASSED${NC}"
ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }
    [[ $TESTS_FAILED -gt 0 ]] && echo -e "  ${RED}Failed: $TESTS_FAILED${NC}"
ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }
    [[ $TESTS_SKIPPED -gt 0 ]] && echo "  Skipped: $TESTS_SKIPPED"
ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }
    echo "══════════════════════════════════════════"
ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }
    [[ $TESTS_FAILED -eq 0 ]]
ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }
}
ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }

ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }
run_all_tests
ssert_file_exists() { [[ -f "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
ssert_dir_exists() { [[ -d "$1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }

assert_true() { [[ "${1:-}" == "true" ]] || [[ "${1:-}" == "0" ]] || [[ "${1:-}" == "1" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Got='$1')"; return 1; }; }
assert_file_exists() { [[ -f "${1:-}" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (File=$1)"; return 1; }; }
assert_dir_exists() { [[ -d "${1:-}" ]] || { echo -e "${RED}  ✗ FAIL: ${2}${NC} (Dir=$1)"; return 1; }; }

