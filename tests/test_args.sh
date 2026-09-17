#!/usr/bin/env bash
[[ -n "${_TEST_ARGS_LOADED:-}" ]] && return 0
readonly _TEST_ARGS_LOADED=1

run_args() {
    source "${SCRIPT_DIR}/core/args.sh" 2>/dev/null
    peas_parse_args "$@" 2>/dev/null
}

test_args_default_mode() { run_args 127.0.0.1; assert_eq "normal" "$(peas_get_mode)" "default mode"; }
test_args_fast_mode() { run_args --fast 127.0.0.1; assert_eq "fast" "$(peas_get_mode)" "fast mode"; }
test_args_aggressive_mode() { run_args --aggressive 127.0.0.1; assert_eq "aggressive" "$(peas_get_mode)" "aggressive mode"; }
test_args_json_format() { run_args --json 127.0.0.1; assert_eq "json" "$(peas_get_output_format)" "json format"; }
test_args_default_format() { run_args 127.0.0.1; assert_eq "text" "$(peas_get_output_format)" "default format"; }
test_args_ip_target() { run_args 10.10.10.24; assert_eq "10.10.10.24" "${TARGETS[0]}" "ip target"; }
test_args_cidr_target() { run_args 10.10.10.0/24; assert_eq "10.10.10.0/24" "${TARGETS[0]}" "cidr target"; }
test_args_hostname_target() { run_args hostname.local; assert_eq "hostname.local" "${TARGETS[0]}" "hostname target"; }
test_args_timeout() { run_args --timeout 10 127.0.0.1; assert_eq "10" "$(peas_get_timeout)" "timeout"; }
test_args_default_timeout() { run_args 127.0.0.1; assert_eq "5" "$(peas_get_timeout)" "default timeout"; }
test_args_parallel() { run_args --parallel 8 127.0.0.1; assert_eq "8" "$(peas_get_parallel)" "parallel"; }
test_args_default_parallel() { run_args 127.0.0.1; assert_eq "4" "$(peas_get_parallel)" "default parallel"; }
test_args_verbose_flag() { run_args --verbose 127.0.0.1; assert_eq "1" "$VERBOSE" "verbose flag"; }
test_args_debug_flag() { run_args --debug 127.0.0.1; assert_eq "2" "$VERBOSE" "debug flag"; }
test_args_no_target_fails() { local ec=0; run_args || ec=$?; assert_eq "2" "$ec" "no target exits 2"; }
test_args_unknown_option_fails() { local ec=0; run_args --bad-opt 127.0.0.1 || ec=$?; assert_eq "3" "$ec" "unknown option exits 3"; }
test_args_multiple_targets() { run_args 127.0.0.1 127.0.0.2; assert_eq "127.0.0.1" "${TARGETS[0]}" "first target"; assert_eq "127.0.0.2" "${TARGETS[1]}" "second target"; }
test_args_state_dir() { run_args --state-dir /tmp/test 127.0.0.1; assert_eq "/tmp/test" "$STATE_DIR" "state dir"; }
test_args_combined_flags() { run_args --fast --json --timeout 3 127.0.0.1; assert_eq "fast" "$(peas_get_mode)" "combined fast"; assert_eq "json" "$(peas_get_output_format)" "combined json"; assert_eq "3" "$(peas_get_timeout)" "combined timeout"; }

test_args_tests() {
    for t in test_args_default_mode test_args_fast_mode test_args_aggressive_mode test_args_json_format test_args_default_format test_args_ip_target test_args_cidr_target test_args_hostname_target test_args_timeout test_args_default_timeout test_args_parallel test_args_default_parallel test_args_verbose_flag test_args_debug_flag test_args_no_target_fails test_args_unknown_option_fails test_args_multiple_targets test_args_state_dir test_args_combined_flags; do
        run_test "$t" "$t"
    done
}
test_args_tests
