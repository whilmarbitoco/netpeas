#!/usr/bin/env bash
#
# NetPEAS — modules/ad.sh
# Active Directory / LDAP extended enumeration
#

ad_module() {
    local host="$1"
    local port="$2"
    local state_dir="$3"

    local output_file="${state_dir}/ad_${host}_${port}.txt"
    : > "$output_file"

    peas_info "Active Directory — $host:$port"

    if ! peas_has_tool ldapsearch; then
        peas_warn "ldapsearch not available; skipping AD enumeration"
        return 1
    fi

    # ── Anonymous Bind & Naming Contexts ────────────────────────────────────
    local naming_contexts
    naming_contexts="$(peas_exec_silent 10 ldapsearch -x -H "ldap://${host}:${port}" -s base namingContexts 2>/dev/null || echo "")"
    echo "$naming_contexts" > "$output_file"

    if ! echo "$naming_contexts" | grep -q "namingContexts"; then
        peas_debug "No AD/LDAP data returned"
        return 0
    fi

    peas_add_finding "$host" "$port" "ad" "auth" "high" "confirmed" \
        "LDAP anonymous bind" "Server returned naming contexts without credentials" "ldapsearch" \
        "Disable anonymous LDAP bind"

    # Extract domain info
    local root_dn="$(echo "$naming_contexts" | grep "namingContexts:" | head -1 | awk '{print $2}')"
    local domain="$(echo "$host" | sed 's/\..*//')"

    # ── Domain Information ────────────────────────────────────────────────
    local domain_info
    domain_info="$(peas_exec_silent 10 ldapsearch -x -H "ldap://${host}:${port}" -s base -b "" defaultNamingContext schemaNamingContext 2>/dev/null || echo "")"
    echo "$domain_info" >> "$output_file"

    # ── Password Policy ──────────────────────────────────────────────────
    local pw_policy
    pw_policy="$(peas_exec_silent 10 ldapsearch -x -H "ldap://${host}:${port}" -s base -b "${root_dn}"         lockoutDuration maxPwdAge minPwdLength pwdHistoryLength 2>/dev/null || echo "")"
    echo "$password_policy" >> "$output_file"

    if [[ -n "$pw_policy" ]]; then
        local lockout_dur="$(echo "$pw_policy" | grep "lockoutDuration:" | awk '{print $2}')"
        local max_pwd_age="$(echo "$pw_policy" | grep "maxPwdAge:" | awk '{print $2}')"
        local min_pwd_len="$(echo "$pw_policy" | grep "minPwdLength:" | awk '{print $2}')"

        if [[ -n "$min_pwd_len" && "$min_pwd_len" -lt 8 ]]; then
            peas_add_finding "$host" "$port" "ad" "policy" "medium" "confirmed" \
                "Weak password policy" "Minimum password length: $min_pwd_len" "ldapsearch" \
                "Enforce minimum 12-character password policy"
        fi

        if [[ -n "$lockout_dur" && "$lockout_dur" == "-1" || "$lockout_dur" == "0" ]]; then
            peas_add_finding "$host" "$port" "ad" "policy" "high" "confirmed" \
                "No account lockout policy" "lockoutDuration not configured" "ldapsearch" \
                "Configure account lockout threshold"
        fi
    fi

    # ── User Enumeration ─────────────────────────────────────────────────
    local users
    users="$(peas_exec_silent 15 ldapsearch -x -H "ldap://${host}:${port}" -b "${root_dn}" \
        "(objectClass=user)" sAMAccountName 2>/dev/null | grep "sAMAccountName:" | head -20)"
    echo "$users" >> "$output_file"

    if [[ -n "$users" ]]; then
        local user_count="$(echo "$users" | grep -c "sAMAccountName:")"
        peas_add_finding "$host" "$port" "ad" "enum" "high" "confirmed" \
            "User enumeration via LDAP" "Found $user_count user accounts" "ldapsearch" \
            "Restrict LDAP anonymous queries"

        # Check for default accounts
        local default_accounts=""
        echo "$users" | grep -qi "Administrator" && default_accounts="${default_accounts}Administrator, "
        echo "$users" | grep -qi "Guest" && default_accounts="${default_accounts}Guest, "
        echo "$users" | grep -qi "krbtgt" && default_accounts="${default_accounts}krbtgt, "

        if [[ -n "$default_accounts" ]]; then
            peas_add_finding "$host" "$port" "ad" "config" "high" "observed" \
                "Default accounts visible" "Accounts: ${default_accounts%, }" "ldapsearch" \
                "Disable or rename default accounts"
        fi
    fi

    # ── Group Enumeration ────────────────────────────────────────────────
    local groups
    groups="$(peas_exec_silent 15 ldapsearch -x -H "ldap://${host}:${port}" -b "${root_dn}" \
        "(objectClass=group)" cn member 2>/dev/null | grep -E "^(cn|member):" | head -30)"
    echo "$groups" >> "$output_file"

    if [[ -n "$groups" ]]; then
        local group_count="$(echo "$groups" | grep -c "^cn:")"
        peas_add_finding "$host" "$port" "ad" "enum" "medium" "confirmed" \
            "Group enumeration via LDAP" "Found $group_count groups" "ldapsearch" \
            "Restrict LDAP anonymous queries"
    fi

    # ── Computer Enumeration ─────────────────────────────────────────────
    local computers
    computers="$(peas_exec_silent 15 ldapsearch -x -H "ldap://${host}:${port}" -b "${root_dn}" \
        "(objectClass=computer)" dNSHostName operatingSystem 2>/dev/null | grep -E "^(dNSHostName|operatingSystem):" | head -20)"
    echo "$computers" >> "$output_file"

    if [[ -n "$computers" ]]; then
        local comp_count="$(echo "$computers" | grep -c "dNSHostName:")"
        peas_add_finding "$host" "$port" "ad" "enum" "medium" "confirmed" \
            "Computer enumeration via LDAP" "Found $comp_count computer accounts" "ldapsearch" \
            "Restrict LDAP anonymous queries"
    fi

    # ── Trust Enumeration ───────────────────────────────────────────────
    local trusts
    trusts="$(peas_exec_silent 10 ldapsearch -x -H "ldap://${host}:${port}" -b "${root_dn}" \
        "(objectClass=trustedDomain)" trustPartner trustDirection 2>/dev/null || echo "")"
    echo "$trusts" >> "$output_file"

    if [[ -n "$trusts" ]]; then
        peas_add_finding "$host" "$port" "ad" "trust" "high" "confirmed" \
            "Domain trust enumeration" "Trust information exposed" "ldapsearch" \
            "Restrict anonymous LDAP queries"
    fi

    # ── Kerberos Pre-Auth Check ─────────────────────────────────────────
    if peas_has_tool nmap; then
        local kerb_check
        kerb_check="$(peas_exec_silent 15 nmap -p 88 --script krb5-enum-users --script-args krb5-enum-users.realm="$domain" "$host" 2>/dev/null || echo "")"
        if [[ -n "$kerb_check" ]]; then
            echo "$kerb_check" >> "$output_file"
            if echo "$kerb_check" | grep -qi "valid"; then
                peas_add_finding "$host" "$port" "ad" "kerberos" "high" "confirmed" \
                    "Kerberos user enumeration" "Valid usernames found via Kerberos" "nmap" \
                    "Disable Kerberos pre-authentication where not needed"
            fi
        fi
    fi

    # ── SPN Enumeration (Kerberoasting target) ─────────────────────────
    local spns
    spns="$(peas_exec_silent 15 ldapsearch -x -H "ldap://${host}:${port}" -b "${root_dn}" \
        "(&(objectClass=user)(servicePrincipalName=*))" sAMAccountName servicePrincipalName 2>/dev/null || echo "")"
    echo "$spns" >> "$output_file"

    if [[ -n "$spns" ]]; then
        local spn_count="$(echo "$spns" | grep -c "servicePrincipalName:")"
        peas_add_finding "$host" "$port" "ad" "kerberos" "high" "confirmed" \
            "Service Principal Names exposed" "Found $spn_count SPNs (Kerberoasting target)" "ldapsearch" \
            "Restrict anonymous LDAP queries"
    fi

    # ── GPO Enumeration ─────────────────────────────────────────────────
    local gpo_shares
    gpo_shares="$(peas_exec_silent 10 smbclient -L "\\\\$host" -N 2>/dev/null | grep -i "sysvol\|policy" || echo "")"
    if [[ -n "$gpo_shares" ]]; then
        peas_add_finding "$host" "$port" "ad" "gpo" "medium" "observed" \
            "SYSVOL share accessible" "GPO files may be readable" "smbclient" \
            "Review SYSVOL permissions for GPP passwords"
    fi

    # ── Intelligence ────────────────────────────────────────────────────
    local exploit_results
    exploit_results="$(peas_searchsploit "Active Directory" 5 2>/dev/null || echo "")"
    if [[ -n "$exploit_results" ]]; then
        echo "$exploit_results" >> "$output_file"
        peas_add_finding "$host" "$port" "ad" "cve" "medium" "likely" \
            "Known AD exploits" "$exploit_results" "searchsploit" \
            "Review and patch"
    fi

    return 0
}