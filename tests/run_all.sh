#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$SCRIPT_DIR"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
TOTAL=0; PASSED=0; FAILED=0

run_test() {
    local name="$1" script="$2"
    ((TOTAL++))
    echo -e "${YELLOW}  ▶ $name${NC}"
    local result tmpfile
    tmpfile="$(mktemp)"
    cat > "$tmpfile" << TESTEOF
#!/usr/bin/env bash
set -uo pipefail
source '${SCRIPT_DIR}/core/args.sh' 2>/dev/null
$script
TESTEOF
    if bash "$tmpfile" 2>/dev/null; then
        ((PASSED++))
        echo -e "${GREEN}  ✓ PASS${NC}"
    else
        ((FAILED++))
    fi
    rm -f "$tmpfile"
}

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║        NetPEAS Test Suite v1.0          ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "━━━ test_args ━━━"

run_test "default_mode" "[[ \$(peas_parse_args 127.0.0.1 >/dev/null 2>&1; peas_get_mode) == normal ]]"
run_test "fast_mode" "[[ \$(peas_parse_args --fast 127.0.0.1 >/dev/null 2>&1; peas_get_mode) == fast ]]"
run_test "aggressive_mode" "[[ \$(peas_parse_args --aggressive 127.0.0.1 >/dev/null 2>&1; peas_get_mode) == aggressive ]]"
run_test "json_format" "[[ \$(peas_parse_args --json 127.0.0.1 >/dev/null 2>&1; peas_get_output_format) == json ]]"
run_test "default_format" "[[ \$(peas_parse_args 127.0.0.1 >/dev/null 2>&1; peas_get_output_format) == text ]]"
run_test "ip_target" "peas_parse_args 10.10.10.24 >/dev/null 2>&1; [[ \${TARGETS[0]} == 10.10.10.24 ]]"
run_test "cidr_target" "peas_parse_args 10.10.10.0/24 >/dev/null 2>&1; [[ \${TARGETS[0]} == 10.10.10.0/24 ]]"
run_test "hostname_target" "peas_parse_args hostname.local >/dev/null 2>&1; [[ \${TARGETS[0]} == hostname.local ]]"
run_test "timeout" "[[ \$(peas_parse_args --timeout 10 127.0.0.1 >/dev/null 2>&1; peas_get_timeout) == 10 ]]"
run_test "default_timeout" "[[ \$(peas_parse_args 127.0.0.1 >/dev/null 2>&1; peas_get_timeout) == 5 ]]"
run_test "parallel" "[[ \$(peas_parse_args --parallel 8 127.0.0.1 >/dev/null 2>&1; peas_get_parallel) == 8 ]]"
run_test "default_parallel" "[[ \$(peas_parse_args 127.0.0.1 >/dev/null 2>&1; peas_get_parallel) == 4 ]]"
run_test "verbose" "peas_parse_args --verbose 127.0.0.1 >/dev/null 2>&1; [[ \$VERBOSE == 1 ]]"
run_test "debug" "peas_parse_args --debug 127.0.0.1 >/dev/null 2>&1; [[ \$VERBOSE == 2 ]]"
run_test "no_target_fails" "peas_parse_args 2>/dev/null; [[ \$? -eq 2 ]]"
run_test "unknown_option_fails" "peas_parse_args --bad 127.0.0.1 2>/dev/null; [[ \$? -eq 3 ]]"
run_test "multiple_targets" "peas_parse_args 127.0.0.1 127.0.0.2 >/dev/null 2>&1; [[ \${TARGETS[0]} == 127.0.0.1 && \${TARGETS[1]} == 127.0.0.2 ]]"
run_test "state_dir" "peas_parse_args --state-dir /tmp/x 127.0.0.1 >/dev/null 2>&1; [[ \$STATE_DIR == /tmp/x ]]"
run_test "combined_flags" "peas_parse_args --fast --json --timeout 3 127.0.0.1 >/dev/null 2>&1; [[ \$(peas_get_mode) == fast && \$(peas_get_output_format) == json && \$(peas_get_timeout) == 3 ]]"

echo ""
echo "══════════════════════════════════════════"
echo "  Total: $TOTAL"
echo -e "  ${GREEN}Passed: $PASSED${NC}"
[[ $FAILED -gt 0 ]] && echo -e "  ${RED}Failed: $FAILED${NC}"
echo "══════════════════════════════════════════"
[[ $FAILED -eq 0 ]]
