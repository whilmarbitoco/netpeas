# NetPEAS

Network Enumeration, Fingerprinting & Vulnerability Triage

**By: Whilmar Bitoco**

---

## Quick Start

```bash
./netpeas <target>
./netpeas 10.10.10.24
./netpeas --fast 192.168.1.0/24
./netpeas --json --aggressive target.local
./netpeas --targets-file targets.txt --parallel 8
```

---

## Modes

| Mode | Flag | Behavior |
|------|------|----------|
| Fast | `--fast` | Top ports, max parallelism |
| Normal | default | Standard scan |
| Aggressive | `--aggressive` | Deep enum, longer timeouts |

---

## Options

```
Target:
  IP address, CIDR (10.0.0.0/24), hostname, or range (10.0.0.1-254)

Modes:
  -f, --fast            Fast scan (top ports, max parallelism)
  -a, --aggressive      Deep enumeration with longer timeouts
  -j, --json            JSON output

Filtering:
  --min-severity LEVEL  Minimum severity (INFO|LOW|MEDIUM|HIGH|CRITICAL)
  --service LIST        Comma-separated service filter (http,ssh,smb)
  --module LIST         Comma-separated module filter (http,ssh,smb)

Options:
  -t, --timeout SECS    Timeout per command (default: 300)
  -p, --parallel N      Parallel workers (default: 4)
  -s, --state-dir DIR   State directory for scan results
  --targets-file FILE   File with targets (one per line)
  --resume              Resume interrupted scan
  --log-file PATH       Debug log file
  --findings-only       Suppress enumeration output
  --no-intel            Skip SearchSploit/CVE lookup
  --verbose, -v         Verbose output
  --debug               Debug output (very verbose)
  -h, --help            Show help
  -V, --version         Show version

Examples:
  netpeas 10.10.10.24
  netpeas --fast --json 10.10.10.24
  netpeas --min-severity HIGH --service http,ssh 10.10.10.24
  netpeas --targets-file targets.txt --parallel 8
  netpeas --resume --state-dir /tmp/netpeas
```

---

## Required Tools

- **nmap** — Service discovery

## Optional Tools (graceful degradation)

| Category | Tools |
|----------|-------|
| HTTP/HTTPS | curl, wget, openssl, whatweb, sslscan, nikto |
| SMB | smbclient, rpcclient, enum4linux-ng |
| DNS | dig, nslookup |
| SNMP | snmpwalk |
| Databases | mysql, psql, redis-cli |
| Other | searchsploit, nc, ftp |

---

## Services Enumerated

| Service | Capabilities |
|---------|-------------|
| HTTP | Security headers, OPTIONS test, path probing, fingerprinting |
| HTTPS | TLS version, cert inspection, cipher enumeration |
| SSH | Algorithm enumeration, weak cipher detection, host key |
| SMB | Null session, share enumeration, SMBv1 detection |
| FTP | Anonymous login, banner |
| DNS | Zone transfer, DNSSEC, open resolver, subdomain brute |
| SMTP | VRFY/EXPN user enum, open relay test |
| Redis | CONFIG GET, DBSIZE, unauth detection |
| MySQL | Root no-password, anonymous access |
| PostgreSQL | Trust auth, version extraction |
| SNMP | Multiple community strings, system info |
| LDAP | Anonymous bind, naming contexts |
| Unknown | Banner-based identification |

---

## Architecture

```
netpeas                  Entry point
├── core/
│   ├── args.sh          Argument parsing & global config
│   ├── discovery.sh     Nmap-based host/service discovery
│   ├── scheduler.sh     Service-to-module dispatch
│   ├── executor.sh      Safe command execution with timeout
│   ├── findings.sh      Finding collection & rendering
│   ├── searchsploit.sh  SearchSploit adapter with cache
│   └── cve.sh           CVE adapter with version matching
├── lib/
│   ├── colors.sh        Terminal color & formatting helpers
│   ├── utils.sh         Validation, temp dirs, concurrency
│   ├── tools.sh         Auto-detection of 20+ security tools
│   ├── cidr.sh          CIDR / range expansion
│   ├── state.sh         Scan state persistence & resumption
│   ├── correlation.sh   Evidence correlation & confidence scoring
│   └── logging.sh       Structured logging & rate limiting
└── modules/
    ├── http.sh          HTTP enumeration
    ├── https.sh         HTTPS/TLS enumeration
    ├── ssh.sh           SSH algorithm enumeration
    ├── smb.sh           SMB share & session enumeration
    ├── ftp.sh           FTP anonymous login test
    ├── dns.sh           DNS zone transfer & records
    ├── smtp.sh          SMTP VRFY/EXPN enumeration
    ├── ldap.sh          LDAP anonymous bind
    ├── snmp.sh          SNMP community string testing
    ├── mysql.sh         MySQL root no-password
    ├── postgres.sh      PostgreSQL trust auth
    ├── redis.sh         Redis unauthenticated INFO
    └── unknown.sh       Unknown service identification
```

---

## Output Modes

### Text (default)
```
╔══════════════════════════════════════════╗
║  NetPEAS v1.0 — Network Enum & Triage  ║
║        By: Whilmar Bitoco              ║
╚══════════════════════════════════════════╝

═══ Discovery — 127.0.0.1 ═══
[+] Found: 127.0.0.1:22 ssh
[+] Found: 127.0.0.1:80 http
[+] Found: 127.0.0.1:443 https

═══ Findings ═══
  127.0.0.1:22 — Weak SSH algorithms detected
    Service: ssh
    Severity: MEDIUM | Confidence: observed
    Evidence: Weak: aes128-cbc, hmac-md5
    Recommendation: Disable weak ciphers
```

### JSON (`--json`)
```json
{
  "scan_id": "1789619852",
  "timestamp": "2026-09-17T03:37:48Z",
  "mode": "normal",
  "total_findings": 2,
  "findings": [
    {
      "host": "127.0.0.1",
      "port": "22",
      "service": "ssh",
      "type": "weak_algorithms",
      "severity": "MEDIUM",
      "confidence": "observed",
      "title": "Weak SSH algorithms detected",
      "evidence": "Weak: aes128-cbc, hmac-md5",
      "source": "ssh",
      "recommendation": "Disable weak ciphers"
    }
  ]
}
```

---

## Install / Update / Uninstall

```bash
./install.sh              # Install wrapper to ~/.local/bin/netpeas
./install.sh /usr/local/bin  # Install system-wide (requires root)
./update.sh               # Update to latest version
./uninstall.sh            # Remove wrapper
```

---

## Features

- **Pure Bash** — No Python, Go, Rust, or Node.js dependencies
- **Graceful Degradation** — Optional tools auto-detected; missing tools skip safely
- **Structured Findings** — Every finding carries host, port, service, severity, confidence, evidence, recommendation
- **Severity Levels** — INFO, LOW, MEDIUM, HIGH, CRITICAL
- **Confidence Labels** — detected, observed, likely, confirmed
- **CIDR / Range Support** — `10.0.0.0/24`, `10.0.0.1-254`
- **Multi-Target** — Multiple targets on CLI or via `--targets-file`
- **Scan Resumption** — `--resume` skips already-completed targets
- **Logging** — `--log-file` for debug tracing
- **Rate Limiting** — Built-in request throttling
- **Intelligence Pipeline** — SearchSploit integration with caching
- **Evidence Correlation** — Cross-reference CVEs with multiple sources
- **JSON Output** — Machine-parseable output for automation
- **Install/Update/Uninstall** — One-command setup

---

## License

MIT
