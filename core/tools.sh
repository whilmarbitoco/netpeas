#!/usr/bin/env bash
#
# NetPEAS — core/tools.sh
# Native security tool detection and abstraction.
#

# Required tools (scan won't run without these)
readonly REQUIRED_TOOLS=(nmap)

# Optional tools (scan degrades without them)
declare -A OPTIONAL_TOOLS=(
    [masscan]="Fast port scanner (alternative to nmap -T4)"
    [naabu]="Fast port scanner (alternative to nmap)"
    [curl]="HTTP/HTTPS client"
    [wget]="HTTP/HTTPS downloader"
    [dig]="DNS lookup utility"
    [nslookup]="DNS lookup utility (fallback)"
    [smbclient]="SMB/CIFS client"
    [rpcclient]="SMB/RPC client"
    [enum4linux-ng]="SMB enumeration tool"
    [whatweb]="Web technology fingerprinting"
    [sslscan]="TLS/SSL scanner"
    [openssl]="TLS/SSL toolkit"
    [nikto]="Web vulnerability scanner"
    [searchsploit]="Exploit-DB search tool"
    [snmpwalk]="SNMP enumeration"
    [ldapsearch]="LDAP directory client"
    [redis-cli]="Redis client"
    [mysql]="MySQL client"
    [psql]="PostgreSQL client"
    [ssh]="SSH client"
    [ftp]="FTP client"
    [nc]="Netcat"
    [timeout]="Timeout command"
    [showmount]="NFS showmount"
    [rpcinfo]="RPC info"
    [sqlplus]="Oracle SQL*Plus"
    [impacket]="Impacket (Python)"
    [ssh-keygen]="SSH key generator"
    [ssh-keyscan]="SSH key scanner"
    [ncat]="Ncat"
    [nmap]="Network scanner"
)

# Detected tools cache
declare -A TOOL_FOUND=()

# ── Detection ─────────────────────────────────────────────────────────────────

peas_detect_tools() {
    local found=0 missing=0

    peas_subsection "Native Toolkit Detection"

    # Check required
    for tool in "${REQUIRED_TOOLS[@]}"; do
        if command -v "$tool" &>/dev/null; then
            TOOL_FOUND[$tool]=1
            peas_detail "${tool} ................ FOUND"
            ((found++))
        else
            TOOL_FOUND[$tool]=0
            peas_error "Required tool '${tool}' not found"
            ((missing++))
        fi
    done

    # Check optional
    for tool in "${!OPTIONAL_TOOLS[@]}"; do
        if command -v "$tool" &>/dev/null; then
            TOOL_FOUND[$tool]=1
            peas_detail "${tool} ........... FOUND"
            ((found++))
        else
            TOOL_FOUND[$tool]=0
            peas_debug "${tool} ......... NOT FOUND"
        fi
    done

    if [[ "$missing" -gt 0 ]]; then
        peas_error "Missing ${missing} required tool(s). Cannot continue."
        return 1
    fi

    peas_info "Found ${found} security tools"
    return 0
}

# ── Query tool availability ───────────────────────────────────────────────────

peas_has_tool() {
    [[ "${TOOL_FOUND[$1]:-0}" -eq 1 ]]
}

# ── Get tool path ──────────────────────────────────────────────────────────────

peas_tool_path() {
    command -v "$1" 2>/dev/null || echo ""
}

# ── SearchSploit adapter ─────────────────────────────────────────────────────

peas_searchsploit() {
    local query="$1"
    local max_results="${2:-5}"

    if ! peas_has_tool searchsploit; then
        peas_debug "SearchSploit not available; skipping exploit lookup"
        return 1
    fi

    local results
    results="$(searchsploit --colour "$query" 2>/dev/null | head -$((max_results + 3)) | tail -n +3 | head -"$max_results")"

    if [[ -n "$results" ]]; then
        echo "$results"
        return 0
    fi
    return 1
}

# ── Version extraction helper ─────────────────────────────────────────────────

peas_extract_version() {
    local text="$1"
    # Common version patterns: Product/X.Y.Z, vX.Y.Z, etc.
    echo "$text" | grep -oP '(v?\\d+\\.\\d+\\.?\\d*)' | head -1
}
