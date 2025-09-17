# EliteMini System Backup

This repository contains a complete backup and restoration system for the EliteMini server configuration.

## Overview

This system provides:
- **Secure RDP access** via Cloudflare Tunnel 
- **Lightweight XFCE desktop** environment
- **Enhanced security monitoring** and logging
- **Automated security updates**
- **Complete system hardening**

## Quick Start

### Backup Current System
```bash
cd /home/sunwolf/system-backup
./backup-system.sh
```

### Restore System
```bash
cd /home/sunwolf/system-backup  
./restore-system.sh
```

## System Architecture

### Core Components
- **Cloudflared**: Secure tunnel for RDP access (no open ports)
- **XRDP + XFCE**: Lightweight remote desktop
- **UFW Firewall**: Locked down, only local RDP allowed
- **Monitoring**: Automated health checks and security monitoring
- **Auto-Updates**: Security patches applied automatically

### Key Features
- ✅ **Zero open ports** - all access via Cloudflare Tunnel
- ✅ **Idle timeout disabled** - persistent RDP sessions
- ✅ **Security hardening** - sudo logging, failed attempt monitoring
- ✅ **Automatic recovery** - services auto-restart on failure
- ✅ **Complete backup/restore** - reproducible system state

## Configuration Files Backed Up

### RDP & Desktop
- `/etc/xrdp/xrdp.ini` - Enhanced keepalive settings
- `/etc/xrdp/sesman.ini` - Session management 
- `~/.xsession` - XFCE desktop startup

### Security & Networking  
- `/etc/cloudflared/` - Tunnel configuration
- `/etc/ufw/user.rules` - Firewall rules
- `/etc/sudoers.d/` - Sudo security policies
- `/etc/rsyslog.d/50-security-monitoring.conf` - Security logging

### Services & Automation
- `/etc/systemd/system/cloudflared.service` - Enhanced tunnel service
- `/etc/apt/apt.conf.d/50unattended-upgrades` - Auto-updates
- Custom monitoring scripts in `/usr/local/bin/`

## Usage Instructions

### Fresh System Setup
1. Clone this repository
2. Run `./restore-system.sh`
3. Configure Cloudflare tunnel authentication
4. Test RDP connection
5. System ready!

### Regular Backup
```bash
# Run backup (automated via cron recommended)
./backup-system.sh

# Commit changes to Git
git add -A
git commit -m "System backup $(date '+%Y-%m-%d %H:%M')"
git push
```

### Emergency Recovery
If you lose access:
1. Boot from USB/rescue mode
2. Clone this repository 
3. Run restoration script
4. Reboot - system will be identical to backup

## Security Features

### Monitoring
- RDP login attempts logged to `/var/log/rdp-access.log`
- Failed authentication attempts in `/var/log/auth-failures.log`
- Cloudflared health monitoring every 5 minutes
- Connection pattern analysis every 15 minutes

### Hardening
- Firewall blocks all incoming except local RDP
- Sudo sessions logged with I/O recording
- Automatic security updates enabled
- Unnecessary services disabled (GNOME, Bluetooth, CUPS, etc.)

### Auto-Recovery
- Services restart on failure with backoff
- Tunnel reconnects automatically
- Failed login monitoring with alerts
- System resource monitoring

## Troubleshooting

### RDP Connection Issues
```bash
# Check tunnel status
sudo systemctl status cloudflared

# Check RDP service  
sudo systemctl status xrdp

# View recent RDP logs
sudo tail -f /var/log/rdp-access.log
```

### Monitoring Logs
```bash
# Security alerts
sudo tail -f /var/log/security-alerts.log

# Cloudflared health
sudo tail -f /var/log/cloudflared-monitor.log

# Connection patterns
sudo tail -f /var/log/connection-monitor.log
```

### Emergency Access
If RDP fails, you have these options:
1. **Physical access** to the machine
2. **SSH** (if enabled)  
3. **Console access** via hosting provider

## System Requirements
- Ubuntu 24.04 LTS or compatible
- Minimum 2GB RAM (8GB+ recommended)
- 20GB+ disk space
- Cloudflare account with tunnel configured

## Backup Schedule Recommendation
- **Daily**: Automated backup via cron
- **Weekly**: Full system verification
- **Monthly**: Test restoration process on separate system

---

**Last Updated**: $(date)
**System**: Ubuntu 24.04 LTS  
**Architecture**: x86_64