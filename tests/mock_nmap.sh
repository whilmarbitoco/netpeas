#!/usr/bin/env bash
# Mock nmap - NetPEAS testing (expanded for all 22+ services)
ofile=""
nfile=""
while [ $# -gt 0 ]; do
  case "$1" in
    -oG) ofile="$2"; shift ;;
    -oN) nfile="$2"; shift ;;
  esac
  shift
done
MOCK='# Nmap 7.95 scan report
Host: 127.0.0.1 ()	Status: Up
Host: 127.0.0.1 ()	Ports: 21/open/tcp//ftp//vsFTPd 3.0.3/,22/open/tcp//ssh//OpenSSH 8.2p1/,23/open/tcp//telnet//Linux telnetd/,25/open/tcp//smtp//Postfix/,53/open/tcp//dns//BIND 9.16.1/,80/open/tcp//http//Apache 2.4.49/,110/open/tcp//pop3//Dovecot/,143/open/tcp//imap//Dovecot/,161/open/tcp//snmp//net-snmp/,389/open/tcp//ldap//OpenLDAP/,443/open/tcp//https//Apache 2.4.49/,445/open/tcp//smb//Samba 4.13.x/,1433/open/tcp//mssql//Microsoft SQL Server 2019/,1521/open/tcp//oracle//Oracle Database 19c/,2049/open/tcp//nfs//NFS/,2375/open/tcp//docker//Docker API/,3306/open/tcp//mysql//MySQL 8.0.32/,3389/open/tcp//rdp//Microsoft Terminal Services/,5432/open/tcp//postgres//PostgreSQL 14.5/,5900/open/tcp//vnc//VNC/,6379/open/tcp//redis//Redis 6.2.5/,8080/open/tcp//http//Apache Tomcat 9/,8443/open/tcp//https//Apache Tomcat 9/,9090/open/tcp//http//Kubernetes API/
# Nmap done'
[ -n "$ofile" ] && echo "$MOCK" > "$ofile"
[ -n "$nfile" ] && echo "$MOCK" > "$nfile"
exit 0
