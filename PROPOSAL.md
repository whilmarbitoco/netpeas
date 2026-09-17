# NetPEAS v1.1 — Gap Closure Proposal

> Date: 2026-09-17
> Author: Ciel
> Status: Proposed

---

## 1. P0 — Critical Fixes (Must Work)

### 1.1 JSON Output Validity

**Problem:** `--json` produces invalid JSON. Summary prints after closing `}`, comma placement is wrong, human-readable output leaks into stdout.

**Solution:**
- All `peas_*` output functions (`peas_info`, `peas_warn`, `peas_section`, `peas_detail`, `peas_debug`) suppress output when `OUTPUT_FORMAT=json`
- Comma placement: prefix commas between findings (leading comma, not trailing)
- Summary section suppressed entirely in JSON mode
- Final `peas_info "Scan complete"` suppressed in JSON mode

**Files:** `lib/colors.sh`, `core/findings.sh`, `netpeas`

---

### 1.2 Real SearchSploit Adapter

**Problem:** `core/searchsploit.sh` is a stub that returns empty string.

**Solution:** Implement real searchploit query with `--json` parsing, ANSI code stripping, and structured output.

**File:** `core/searchsploit.sh`

---

### 1.3 Parallel Module Execution

**Problem:** Scheduler runs modules sequentially because subshell function inheritance breaks and `set -e` kills arithmetic.

**Solution:** Worker-pool pattern with background jobs, explicit function sourcing in subshells, `$((total + 1))` arithmetic.

**File:** `core/scheduler.sh`

---

### 1.4 Error Handling in Modules

**Problem:** Modules don't check command success — failures are silent.

**Solution:** Add explicit return code checking with `|| { peas_debug "..."; return 1; }` pattern.

**Files:** All `modules/*.sh`

---

## 2. P1 — Deep Module Enhancement

### 2.1 HTTP Module Enhancement
- OPTIONS method test
- Common path probe (`/robots.txt`, `/admin`, `/api`, `/.env`)
- Security headers check (HSTS, CSP, X-Frame-Options)
- Web technology fingerprinting (if `whatweb` available)
- Directory listing detection

### 2.2 HTTPS/TLS Module Enhancement
- TLS version detection (SSLv3, TLS 1.0/1.1/1.2/1.3)
- Certificate inspection (expiry, CN, SAN, issuer, self-signed)
- Cipher suite enumeration (if `sslscan` available)
- Heartbleed check (if `nmap --script ssl-heartbleed` available)

### 2.3 SSH Module Enhancement
- Algorithm enumeration (kex, ciphers, MACs, host key types)
- Weak algorithm detection (CBC mode, MD5, SHA1, diffie-hellman-group1)
- Host key fingerprint + type detection
- Password authentication detection

### 2.4 SMB Module Enhancement
- Share enumeration with access levels
- User RID cycling (if `rpcclient` available)
- SMB signing requirement check
- SMBv1 detection
- OS version extraction
- Anonymous write detection

### 2.5 DNS Module Enhancement
- Zone transfer test with multiple record types
- Common subdomain enumeration (built-in wordlist)
- DNSSEC check
- Open resolver test
- Version query

### 2.6 SMTP Module Enhancement
- VRFY command test (user enumeration)
- EXPN command test (mailing list expansion)
- Open relay test
- STARTTLS support check

### 2.7 Redis Module Enhancement
- CONFIG GET * (enumerate configuration)
- KEY count (SELECT + DBSIZE)
- Version extraction from INFO

### 2.8 MySQL Module Enhancement
- Version extraction from error message
- Anonymous access detection
- Empty password for common users
- SSL requirement check

### 2.9 PostgreSQL Module Enhancement
- Version extraction
- Trust auth detection
- Password authentication detection
- SSL requirement check

### 2.10 SNMP Module Enhancement
- Multiple community strings (public, private, admin, guest, system)
- System info extraction (sysDescr, sysName, sysContact)
- Interface enumeration
- SNMPv3 detection

---

## 3. P2 — Intelligence Pipeline

### 3.1 CVE Cache + False Positive Reduction
- Cache on `product:version` key
- `searchsploit --json` parsing
- Version range matching (basic semver)
- Deduplication across modules

### 3.2 Evidence Correlation
- Compound vulnerability detection
- Combined severity for correlated findings

---

## 4. P3 — Output & Usability

### 4.1 Output Filtering
- `--min-severity INFO|LOW|MEDIUM|HIGH|CRITICAL`
- `--service http,https,smb`
- `--module http,ssh`
- `--findings-only`

### 4.2 Multi-Target + CIDR Expansion
- Multiple targets on command line
- CIDR range expansion
- IP range expansion
- File input (`--targets-file`)

### 4.3 Scan Resumption
- Store module completion status
- `--resume` flag

### 4.4 Logging
- `--log-file path`
- Timestamped entries
- Log rotation

---

## 5. Testing Strategy

- Module unit tests with Docker containers
- E2E integration tests with Docker Compose
- Real target validation (CTF-style)
- Performance benchmark

---

## 6. Implementation Phases

| Phase | Focus | Estimate |
|---|---|---|
| Phase 1 | Core Reliability (JSON, parallel, error handling) | 2-3 hours |
| Phase 2 | Intelligence (SearchSploit, CVE, correlation) | 2-3 hours |
| Phase 3 | Module Deep Enhancement | 3-4 hours |
| Phase 4 | Usability (filtering, multi-target, logging) | 2-3 hours |
| Phase 5 | Testing + Validation | 2-3 hours |

**Total: 11-16 hours**

---

## 7. New Files

```
core/intelligence.sh    — CVE cache + correlation
lib/output.sh           — Output filtering + formatting
tests/test_modules.sh   — Module unit tests (Docker-based)
tests/test_e2e.sh       — Integration tests
scripts/docker-test.sh  — Docker Compose test environment
```

## 8. New Flags

```
--min-severity LEVEL
--service LIST
--module LIST
--targets-file FILE
--resume
--log-file PATH
--findings-only
--no-intel
```

## 9. Acceptance Criteria

- `--json` output is valid JSON
- All modules have deep enumeration
- SearchSploit/CVE works with real data
- Parallel execution works
- Output filtering works
- All tests pass
- Tested against real CTF target
- README updated

---

*End of proposal.*
