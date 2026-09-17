#!/usr/bin/env bash
#
# NetPEAS — modules/k8s.sh
# Kubernetes API enumeration
#

k8s_module() {
    local host="$1"
    local port="$2"
    local state_dir="$3"

    local output_file="${state_dir}/k8s_${host}_${port}.txt"
    : > "$output_file"

    peas_info "Kubernetes API — $host:$port"

    # ── API Version Discovery ──────────────────────────────────────────
    local api_versions
    api_versions="$(peas_exec_silent 10 curl -sk --connect-timeout 5 "https://${host}:${port}/api" 2>/dev/null || echo "")"
    echo "$api_versions" > "$output_file"

    if echo "$api_versions" | grep -q "versions"; then
        peas_add_finding "$host" "$port" "k8s" "auth" "high" "confirmed" \
            "Kubernetes API accessible" "API versions listed without auth" "curl" \
            "Enable RBAC and authentication"
    fi

    # ── Pod Enumeration ────────────────────────────────────────────────
    local pods
    pods="$(peas_exec_silent 10 curl -sk --connect-timeout 5 "https://${host}:${port}/api/v1/pods" 2>/dev/null || echo "")"
    if [[ -n "$pods" ]] && ! echo "$pods" | grep -qi "Forbidden\|Unauthorized"; then
        echo "$pods" >> "$output_file"
        local pod_count="$(echo "$pods" | grep -o '"name"' | wc -l)"
        if [[ $pod_count -gt 0 ]]; then
            peas_add_finding "$host" "$port" "k8s" "enum" "critical" "confirmed" \
                "Kubernetes pods enumerated" "Found $pod_count pods without authentication" "curl" \
                "Enable RBAC and authentication"
        fi
    fi

    # ── Secret Enumeration (critical) ─────────────────────────────────
    local secrets
    secrets="$(peas_exec_silent 10 curl -sk --connect-timeout 5 "https://${host}:${port}/api/v1/secrets" 2>/dev/null || echo "")"
    if [[ -n "$secrets" ]] && ! echo "$secrets" | grep -qi "Forbidden\|Unauthorized"; then
        echo "$secrets" >> "$output_file"
        local secret_count="$(echo "$secrets" | grep -o '"name"' | wc -l)"
        if [[ $secret_count -gt 0 ]]; then
            peas_add_finding "$host" "$port" "k8s" "secret" "critical" "confirmed" \
                "Kubernetes secrets exposed" "Found $secret_count secrets without authentication" "curl" \
                "Enable RBAC, rotate exposed secrets immediately"
        fi
    fi

    # ── Node Information ───────────────────────────────────────────────
    local nodes
    nodes="$(peas_exec_silent 10 curl -sk --connect-timeout 5 "https://${host}:${port}/api/v1/nodes" 2>/dev/null || echo "")"
    if [[ -n "$nodes" ]] && ! echo "$nodes" | grep -qi "Forbidden\|Unauthorized"; then
        echo "$nodes" >> "$output_file"
        local node_count="$(echo "$nodes" | grep -o '"name"' | wc -l)"
        if [[ $node_count -gt 0 ]]; then
            peas_add_finding "$host" "$port" "k8s" "enum" "high" "confirmed" \
                "Kubernetes nodes enumerated" "Found $node_count nodes without authentication" "curl" \
                "Enable RBAC and authentication"
        fi
    fi

    # ── Service Account Token ──────────────────────────────────────────
    local sa_token
    sa_token="$(peas_exec_silent 10 curl -sk --connect-timeout 5 "https://${host}:${port}/api/v1/namespaces/default/serviceaccounts/default" 2>/dev/null || echo "")"
    if [[ -n "$sa_token" ]] && echo "$sa_token" | grep -q "token"; then
        peas_add_finding "$host" "$port" "k8s" "token" "critical" "confirmed" \
            "Default service account token accessible" "Token retrievable via API" "curl" \
            "Enable RBAC, use specific service accounts per pod"
    fi

    # ── RBAC Configuration Check ──────────────────────────────────────
    local rbac
    rbac="$(peas_exec_silent 10 curl -sk --connect-timeout 5 "https://${host}:${port}/apis/rbac.authorization.k8s.io/v1/clusterroles" 2>/dev/null || echo "")"
    if [[ -n "$rbac" ]] && ! echo "$rbac" | grep -qi "Forbidden\|Unauthorized"; then
        echo "$rbac" >> "$output_file"
        # Check for cluster-admin role binding
        if echo "$rbac" | grep -qi "cluster-admin\|admin\|system:masters"; then
            peas_add_finding "$host" "$port" "k8s" "rbac" "high" "observed" \
                "Elevated roles accessible" "Privileged roles visible via API" "curl" \
                "Review RBAC bindings, follow least privilege"
        fi
    fi

    # ── Dashboard Check ────────────────────────────────────────────────
    local dashboard
    dashboard="$(peas_exec_silent 10 curl -sk --connect-timeout 5 "https://${host}:${port}/api/v1/namespaces/kubernetes-dashboard/services" 2>/dev/null || echo "")"
    if [[ -n "$dashboard" ]] && echo "$dashboard" | grep -q "kubernetes-dashboard"; then
        peas_add_finding "$host" "$port" "k8s" "dashboard" "high" "observed" \
            "Kubernetes dashboard exposed" "Dashboard service found" "curl" \
            "Restrict dashboard access with authentication"
    fi

    # ── Intelligence ────────────────────────────────────────────────────
    local exploit_results
    exploit_results="$(peas_searchsploit "Kubernetes" 3 2>/dev/null || echo "")"
    if [[ -n "$exploit_results" ]]; then
        echo "$exploit_results" >> "$output_file"
        peas_add_finding "$host" "$port" "k8s" "cve" "medium" "likely" \
            "Known K8s exploits" "$exploit_results" "searchsploit" \
            "Review and patch"
    fi

    return 0
}