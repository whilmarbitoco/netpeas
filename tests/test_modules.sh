#!/usr/bin/env bash
#
# NetPEAS — test_modules.sh
# Tests for service modules (http, ssh, smb)
#

[[ -n "${_TEST_MODULES_LOADED:-}" ]] && return 0
readonly _TEST_MODULES_LOADED=1

# ── Helpers ───────────────────────────────────────────────────────────────────

test_module_structure() {
    local module="$1"
    local module_file="${SCRIPT_DIR}/modules/${module}.sh"
    
    if [[ ! -f "$module_file" ]]; then
        test_skip "module file not found"
        return 1
    fi
    
    # Check source guard
    grep -q "_NETPEAS_MODULE_${module^^}_LOADED" "$module_file" || {
        echo -e "\033[0;31m  ✗ FAIL: missing source guard in $module\033[0m"
        return 1
    }
    
    # Check module function exists
    grep -q "^${module}_module()" "$module_file" || {
        echo -e "\033[0;31m  ✗ FAIL: missing ${module}_module function\033[0m"
        return 1
    }
    
    return 0
}

# ── Tests ─────────────────────────────────────────────────────────────────────

test_module_http_structure() {
    test_module_structure "http"
}

test_module_https_structure() {
    test_module_structure "https"
}

test_module_ssh_structure() {
    test_module_structure "ssh"
}

test_module_ftp_structure() {
    test_module_structure "ftp"
}

test_module_smb_structure() {
    test_module_structure "smb"
}

test_module_dns_structure() {
    test_module_structure "dns"
}

test_module_smtp_structure() {
    test_module_structure "smtp"
}

test_module_ldap_structure() {
    test_module_structure "ldap"
}

test_module_snmp_structure() {
    test_module_structure "snmp"
}

test_module_mysql_structure() {
    test_module_structure "mysql"
}

test_module_postgres_structure() {
    test_module_structure "postgres"
}

test_module_redis_structure() {
    test_module_structure "redis"
}

test_module_http_fallback() {
    local module_file="${SCRIPT_DIR}/modules/http.sh"
    if [[ ! -f "$module_file" ]]; then
        test_skip "http module not found"
        return
    fi
    
    # Check for curl precheck
    grep -q "peas_has_tool curl" "$module_file" || {
        echo -e "\033[0;31m  ✗ FAIL: http module should check for curl\033[0m"
        return 1
    }
    
    return 0
}

test_module_smb_fallback() {
    local module_file="${SCRIPT_DIR}/modules/smb.sh"
    if [[ ! -f "$module_file" ]]; then
        test_skip "smb module not found"
        return
    fi
    
    # Check for enum4linux-ng → smbclient → rpcclient fallback chain
    grep -q "enum4linux-ng" "$module_file" || {
        echo -e "\033[0;31m  ✗ FAIL: smb module should prefer enum4linux-ng\033[0m"
        return 1
    }
    
    grep -q "smbclient" "$module_file" || {
        echo -e "\033[0;31m  ✗ FAIL: smb module should fallback to smbclient\033[0m"
        return 1
    }
    
    return 0
}

# ── Test runner ───────────────────────────────────────────────────────────────

modules_tests() {
    run_test "module_http_structure" test_module_http_structure
    run_test "module_https_structure" test_module_https_structure
    run_test "module_ssh_structure" test_module_ssh_structure
    run_test "module_ftp_structure" test_module_ftp_structure
    run_test "module_smb_structure" test_module_smb_structure
    run_test "module_dns_structure" test_module_dns_structure
    run_test "module_smtp_structure" test_module_smtp_structure
    run_test "module_ldap_structure" test_module_ldap_structure
    run_test "module_snmp_structure" test_module_snmp_structure
    run_test "module_mysql_structure" test_module_mysql_structure
    run_test "module_postgres_structure" test_module_postgres_structure
    run_test "module_redis_structure" test_module_redis_structure
    run_test "module_http_fallback" test_module_http_fallback
    run_test "module_smb_fallback" test_module_smb_fallback
}

modules_tests
