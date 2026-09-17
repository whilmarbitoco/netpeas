#!/usr/bin/env bash
# Mock nmap for testing - handles -oG and -oN flags
output_file=""
output_n_file=""
target=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -oG) shift; output_file="$1"; shift ;;
        -oN) shift; output_n_file="$1"; shift ;;
        -sC|-sV|-sT|-A|-T4|-T3|--open|--version-intensity) shift ;;
        -F) shift ;;
        *) target="$1"; shift ;;
    esac
done

MOCK_OUTPUT='# Nmap 7.94 scan initiated Thu Sep 16 15:00:00 2026 as: nmap -sC -sV -T4 -oG - 127.0.0.1
Host: 127.0.0.1 ()	Status: Up
Host: 127.0.0.1 ()	Ports: 22/open/tcp//ssh//OpenSSH 8.2p1 Ubuntu 4ubuntu0.5/,80/open/tcp//http//Apache 2.4.49 (Ubuntu)/,443/open/tcp//https//Apache 2.4.49 (Ubuntu)/,3306/open/tcp//mysql//MySQL 8.0.32/	Ignored State: closed (996)
# Nmap done at Thu Sep 16 15:00:05 2026 -- 1 IP address (1 host up) scanned in 5.00 seconds'

if [[ -n "$output_file" ]]; then
    echo "$MOCK_OUTPUT" > "$output_file"
fi
if [[ -n "$output_n_file" ]]; then
    echo "Mock nmap scan report for $target" > "$output_n_file"
fi
