#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="/workspace/netpeas"
export PATH="$SCRIPT_DIR/tests:$PATH"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║     NetPEAS End-to-End Test              ║"
echo "╚══════════════════════════════════════════╝"

# ── Test 1: Full pipeline with mock nmap ────────────────────────────────────
echo ""
echo "━━━ Test: Full pipeline (mock nmap) ━━━"

# Run netpeas against localhost using mock nmap
cd /tmp
output="$(PATH="$SCRIPT_DIR/tests:$PATH" bash "$SCRIPT_DIR/netpeas" 127.0.0.1 2>&1)"
ec=$?

# Check that discovery found services
if echo "$output" | grep -q "Found: 127.0.0.1:22 ssh"; then
    echo "  ✓ SSH discovery"
else
    echo "  ✗ SSH discovery failed"
fi

if echo "$output" | grep -q "Found: 127.0.0.1:80 http"; then
    echo "  ✓ HTTP discovery"
else
    echo "  ✗ HTTP discovery failed"
fi

if echo "$output" | grep -q "Found: 127.0.0.1:443 https"; then
    echo "  ✓ HTTPS discovery"
else
    echo "  ✗ HTTPS discovery failed"
fi

# ── Test 2: --json output ────────────────────────────────────────────────────
echo ""
echo "━━━ Test: JSON output ━━─"

json_output="$(PATH="$SCRIPT_DIR/tests:$PATH" bash "$SCRIPT_DIR/netpeas" --json 127.0.0.1 2>&1)"

# Check JSON validity (basic structure check)
if echo "$json_output" | grep -q '"scan_id"'; then
    echo "  ✓ JSON has scan_id"
fi
if echo "$json_output" | grep -q '"total_findings"'; then
    echo "  ✓ JSON has total_findings"
fi

# ── Test 3: --fast mode ──────────────────────────────────────────────────────
echo ""
echo "━━━ Test: Fast mode ━━━"

fast_output="$(PATH="$SCRIPT_DIR/tests:$PATH" bash "$SCRIPT_DIR/netpeas" --fast 127.0.0.1 2>&1)"
if echo "$fast_output" | grep -q "Mode: fast"; then
    echo "  ✓ Fast mode set"
else
    echo "  ✗ Fast mode failed"
fi

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════"
echo "  E2E tests completed (check above for failures)"
echo "══════════════════════════════════════════"
