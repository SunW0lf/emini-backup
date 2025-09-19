# 🚨 ELITEMINI SERVER RECOVERY PLAN

## Quick Reference - Emergency Commands

### SSH Access
```bash
# Primary SSH access
ssh sunwolf@192.168.1.173

# System identification
hostname -f  # sunwolf-EliteMini
whoami       # sunwolf
```

### Service Restart Procedures

#### RDP Service Failure
```bash
# Check status
sudo systemctl status xrdp
sudo systemctl status lightdm

# Restart services
sudo systemctl restart xrdp
sudo systemctl restart lightdm

# Check logs
sudo tail -20 /var/log/xrdp.log
sudo journalctl -u xrdp -f
```

#### Cloudflared Tunnel Failure
```bash
# Status check
sudo systemctl status cloudflared

# Restart tunnel
sudo systemctl restart cloudflared

# Monitor logs
sudo journalctl -u cloudflared -f

# Test tunnel connectivity
curl -I https://rdp2.immovablerod.quest
```

#### Keep-Awake Service
```bash
# Status and restart
sudo systemctl status keep-awake
sudo systemctl restart keep-awake

# Check anti-sleep log
sudo tail -10 /var/log/keep-awake.log
```

### Manual Healing Script Invocation

#### Run Advanced Health Monitor
```bash
cd /home/sunwolf/emini-backup/emini-backup
./scripts/advanced-health-monitor.sh

# Check results
tail -20 logs/advanced-health-monitor.log
```

#### Manual System Backup
```bash
cd /home/sunwolf/emini-backup/emini-backup
./scripts/enhanced-system-backup.sh

# Verify backup completion
git status
git log --oneline -3
```

#### Emergency Service Monitoring
```bash
# Monitor critical services
./scripts/monitor-cloudflared.sh
./scripts/monitor-connections.sh
```

### Git Restore Procedures

#### Basic Configuration Restore
```bash
cd /home/sunwolf/emini-backup/emini-backup

# Restore system configs
sudo cp backups/system-configs/xrdp.ini /etc/xrdp/
sudo cp backups/system-configs/sshd_config /etc/ssh/
sudo systemctl reload sshd
sudo systemctl restart xrdp

# Restore user configs
cp -r backups/user-configs/xfce4/ ~/.config/
```

#### Full Repository Restore
```bash
# Re-clone if repository corrupted
cd ~
rm -rf emini-backup
git clone https://github.com/SunW0lf/emini-backup.git
cd emini-backup/emini-backup

# Restore cron jobs
crontab -l  # Verify current
# Manual restore if needed:
# */10 * * * * /home/sunwolf/emini-backup/emini-backup/scripts/advanced-health-monitor.sh >/dev/null 2>&1
# 0 1 * * * /home/sunwolf/emini-backup/emini-backup/scripts/enhanced-system-backup.sh >/dev/null 2>&1
```

## Emergency Reinstall Outline

### Phase 1: Base System Recovery
```bash
# After Ubuntu reinstall:
sudo apt update
sudo apt install -y git xrdp lightdm xfce4 cloudflared curl

# Clone backup repository
cd /home/sunwolf
git clone https://github.com/SunW0lf/emini-backup.git
cd emini-backup/emini-backup
```

### Phase 2: Service Configuration
```bash
# Restore system configurations
sudo cp backups/system-configs/xrdp.ini /etc/xrdp/
sudo cp backups/system-configs/keep-awake.service /etc/systemd/system/
sudo systemctl daemon-reload

# Enable services
sudo systemctl enable xrdp
sudo systemctl enable lightdm
sudo systemctl enable keep-awake
sudo systemctl enable cloudflared  # After tunnel reconfiguration
```

### Phase 3: User Environment
```bash
# Restore user configurations
cp -r backups/user-configs/xfce4/ ~/.config/
mkdir -p ~/.config/warp-terminal
cp backups/user-configs/warp-terminal/user_preferences.json ~/.config/warp-terminal/

# Restore cron jobs
crontab -e
# Add the monitoring and backup cron jobs
```

### Phase 4: Security Hardening
```bash
# Apply SSH hardening
sudo tee /etc/ssh/sshd_config.d/99-security-hardening.conf << 'EOF'
Port 22
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
PermitEmptyPasswords no
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
AllowUsers sunwolf
EOF

# Install fail2ban
sudo apt install -y fail2ban
sudo systemctl enable --now fail2ban

# Configure UFW
sudo ufw enable
sudo ufw allow from 127.0.0.1 to any port 3389
sudo ufw allow from 192.168.1.0/24 to any port 22
```

## Critical Service Dependencies

### Required Running Services
- `xrdp.service` - Remote Desktop Protocol
- `lightdm.service` - Display Manager
- `cloudflared.service` - Tunnel Service
- `keep-awake.service` - Anti-sleep monitoring
- `ssh.service` - SSH access (for emergencies)

### Required Cron Jobs
- Health monitoring: Every 10 minutes
- System backup: Daily at 1 AM

### File System Critical Paths
- `/etc/xrdp/xrdp.ini` - RDP configuration
- `/etc/systemd/system/keep-awake.service` - Anti-sleep service
- `/home/sunwolf/emini-backup/emini-backup/` - Backup repository
- `~/.config/xfce4/` - Desktop environment config

## Troubleshooting Common Issues

### RDP Connection Issues
1. Check if xrdp is listening: `sudo ss -tlnp | grep 3389`
2. Verify tunnel is active: `curl -I https://rdp2.immovablerod.quest`
3. Check firewall rules: `sudo ufw status`
4. Review logs: `sudo tail -20 /var/log/xrdp.log`

### System Sleep Issues
1. Check keep-awake service: `systemctl status keep-awake`
2. Verify systemd sleep targets are masked: `systemctl status sleep.target`
3. Check logind configuration: `cat /etc/systemd/logind.conf`

### Backup Failures
1. Check Git connectivity: `git pull`
2. Verify script permissions: `ls -la scripts/`
3. Review backup logs: `tail -20 logs/enhanced-system-backup.log`
4. Check disk space: `df -h`

## Contact Information

### System Details
- Hostname: sunwolf-EliteMini  
- User: sunwolf
- Local IP: 192.168.1.173
- Repository: https://github.com/SunW0lf/emini-backup.git

### Recovery Priority Order
1. SSH access restoration
2. Critical service restart (xrdp, cloudflared)
3. Health monitoring resumption
4. Full configuration restore
5. Security hardening re-application

**Last Updated:** September 19, 2025