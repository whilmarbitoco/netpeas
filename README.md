# NetPEAS

Network Enumeration, Fingerprinting & Vulnerability Triage

## Quick Start

```bash
./netpeas <target>
./netpeas 10.10.10.24
./netpeas --fast 192.168.1.0/24
./netpeas --json --aggressive target.local
```

## Modes

| Mode | Flag | Behavior |
|------|------|----------|
| Fast | `--fast` | Quick scan, no deep enum |
| Normal | default | Standard scan |
| Aggressive | `--aggressive` | Deep enumeration |
| Verbose | `-v` | Detailed output |
| JSON | `--json` | Machine-readable |

## Requirements

- Linux (Kali Linux recommended)
- nmap (required)
- Standard Unix tools

## Optional Tools

searchsploit, curl, smbclient, enum4linux-ng, dig, openssl, snmpwalk, ldapsearch, redis-cli, mysql, psql, whatweb, sslscan, nikto, naabu, masscan

## License

MIT
