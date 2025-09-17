#!/bin/bash
# System Backup Script for IMMOVABLE-WITNESS
# Creates comprehensive backup of system configuration

set -e

BACKUP_DIR="/home/sunwolf/emini-backup/emini-backup"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')

echo "=== System Backup Started at $(date) ==="

# Create directory structure
mkdir -p "$BACKUP_DIR"/{configs,services,packages,scripts,certs,logs}

echo "1. Backing up critical system configurations..."

# Copy critical system configs (preserve permissions where possible)
sudo cp -p /etc/xrdp/xrdp.ini "$BACKUP_DIR/configs/" 2>/dev/null || echo "xrdp.ini not found"
sudo cp -p /etc/xrdp/sesman.ini "$BACKUP_DIR/configs/" 2>/dev/null || echo "sesman.ini not found"
sudo cp -p /etc/xrdp/*.sh "$BACKUP_DIR/configs/" 2>/dev/null || echo "xrdp scripts not found"

# Cloudflared configs
sudo cp -rp /etc/cloudflared "$BACKUP_DIR/configs/" 2>/dev/null || echo "cloudflared config not found"
cp -rp ~/.cloudflared "$BACKUP_DIR/configs/user-cloudflared" 2>/dev/null || echo "user cloudflared not found"

# Network and security configs
sudo cp -p /etc/ufw/user.rules "$BACKUP_DIR/configs/" 2>/dev/null || echo "UFW rules not found"
sudo cp -p /etc/ufw/user6.rules "$BACKUP_DIR/configs/" 2>/dev/null || echo "UFW IPv6 rules not found"
sudo cp -p /etc/sudoers.d/* "$BACKUP_DIR/configs/" 2>/dev/null || echo "sudoers.d not found"
sudo cp -p /etc/apt/apt.conf.d/50unattended-upgrades "$BACKUP_DIR/configs/" 2>/dev/null || echo "unattended-upgrades not found"
sudo cp -p /etc/rsyslog.d/50-security-monitoring.conf "$BACKUP_DIR/configs/" 2>/dev/null || echo "rsyslog config not found"

# User configs
cp -p ~/.xsession "$BACKUP_DIR/configs/user-xsession" 2>/dev/null || echo "user .xsession not found"
cp -p ~/.profile "$BACKUP_DIR/configs/user-profile" 2>/dev/null || echo "user .profile not found"
cp -p ~/.bashrc "$BACKUP_DIR/configs/user-bashrc" 2>/dev/null || echo "user .bashrc not found"

echo "2. Backing up systemd services..."
sudo systemctl list-unit-files --state=enabled | grep -E "(cloudflared|xrdp|lightdm|unattended-upgrades)" > "$BACKUP_DIR/services/enabled-services.txt"
sudo cp -p /etc/systemd/system/cloudflared.service "$BACKUP_DIR/services/" 2>/dev/null || echo "cloudflared service not found"

echo "3. Creating package manifests..."
dpkg --get-selections > "$BACKUP_DIR/packages/installed-packages.txt"
apt list --installed > "$BACKUP_DIR/packages/apt-installed.txt" 2>/dev/null
snap list > "$BACKUP_DIR/packages/snap-packages.txt" 2>/dev/null || echo "No snap packages"

echo "4. Backing up custom scripts..."
sudo cp -p /usr/local/bin/monitor-*.sh "$BACKUP_DIR/scripts/" 2>/dev/null || echo "No monitoring scripts"
sudo cp -p /usr/local/bin/emergency-*.sh "$BACKUP_DIR/scripts/" 2>/dev/null || echo "No emergency scripts"

echo "5. Creating system information..."
{
    echo "=== System Information ==="
    uname -a
    echo ""
    echo "=== OS Release ==="
    cat /etc/os-release
    echo ""
    echo "=== Network Interfaces ==="
    ip addr show
    echo ""
    echo "=== Disk Usage ==="
    df -h
    echo ""
    echo "=== Memory Info ==="
    free -h
    echo ""
    echo "=== Active Services ==="
    systemctl list-units --type=service --state=active | head -20
} > "$BACKUP_DIR/system-info.txt"

echo "6. Creating restore metadata..."
{
    echo "BACKUP_TIMESTAMP=$TIMESTAMP"
    echo "SYSTEM_HOSTNAME=$(hostname)"
    echo "USER_NAME=$(whoami)"
    echo "BACKUP_PATH=$BACKUP_DIR"
    echo "UBUNTU_VERSION=$(lsb_release -r -s)"
    echo "KERNEL_VERSION=$(uname -r)"
} > "$BACKUP_DIR/backup-metadata.txt"

echo "=== System Backup Completed at $(date) ==="
echo "Backup location: $BACKUP_DIR"