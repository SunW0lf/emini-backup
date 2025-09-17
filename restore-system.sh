#!/bin/bash
# System Restoration Script for IMMOVABLE-WITNESS
# Restores system from backup to reproduce exact configuration

set -e

BACKUP_DIR="/home/sunwolf/emini-backup/emini-backup"

echo "=== System Restoration Started at $(date) ==="

if [[ ! -f "$BACKUP_DIR/backup-metadata.txt" ]]; then
    echo "ERROR: No backup metadata found in $BACKUP_DIR"
    exit 1
fi

# Load backup metadata
source "$BACKUP_DIR/backup-metadata.txt"

echo "Restoring system from backup created on: $BACKUP_TIMESTAMP"
echo "Original system: $SYSTEM_HOSTNAME"

read -p "This will overwrite current system configuration. Continue? (y/N): " confirm
if [[ $confirm != [yY] ]]; then
    echo "Restoration cancelled."
    exit 1
fi

echo "1. Installing required packages..."

# Install base packages for RDP and security
sudo apt update
sudo apt install -y xrdp lightdm xfce4 xfce4-goodies
sudo apt install -y unattended-upgrades apt-listchanges bc rsyslog ufw

# Install cloudflared if not present
if ! command -v cloudflared &> /dev/null; then
    echo "Installing cloudflared..."
    wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
    sudo dpkg -i cloudflared-linux-amd64.deb
    rm cloudflared-linux-amd64.deb
fi

echo "2. Restoring system configurations..."

# Restore xRDP configs
if [[ -f "$BACKUP_DIR/configs/xrdp.ini" ]]; then
    sudo cp "$BACKUP_DIR/configs/xrdp.ini" /etc/xrdp/
    echo "Restored xrdp.ini"
fi

if [[ -f "$BACKUP_DIR/configs/sesman.ini" ]]; then
    sudo cp "$BACKUP_DIR/configs/sesman.ini" /etc/xrdp/
    echo "Restored sesman.ini"
fi

# Restore cloudflared configs
if [[ -d "$BACKUP_DIR/configs/cloudflared" ]]; then
    sudo cp -r "$BACKUP_DIR/configs/cloudflared" /etc/
    echo "Restored cloudflared system config"
fi

if [[ -d "$BACKUP_DIR/configs/user-cloudflared" ]]; then
    cp -r "$BACKUP_DIR/configs/user-cloudflared" ~/.cloudflared
    echo "Restored cloudflared user config"
fi

# Restore user session
if [[ -f "$BACKUP_DIR/configs/user-xsession" ]]; then
    cp "$BACKUP_DIR/configs/user-xsession" ~/.xsession
    chmod +x ~/.xsession
    echo "Restored user .xsession"
fi

# Restore security configs
if [[ -f "$BACKUP_DIR/configs/user.rules" ]]; then
    sudo cp "$BACKUP_DIR/configs/user.rules" /etc/ufw/
    echo "Restored UFW rules"
fi

if [[ -f "$BACKUP_DIR/configs/99-security-timeout" ]]; then
    sudo cp "$BACKUP_DIR/configs/99-security-timeout" /etc/sudoers.d/
    sudo chmod 440 /etc/sudoers.d/99-security-timeout
    echo "Restored sudo security config"
fi

if [[ -f "$BACKUP_DIR/configs/50unattended-upgrades" ]]; then
    sudo cp "$BACKUP_DIR/configs/50unattended-upgrades" /etc/apt/apt.conf.d/
    echo "Restored unattended-upgrades config"
fi

if [[ -f "$BACKUP_DIR/configs/50-security-monitoring.conf" ]]; then
    sudo cp "$BACKUP_DIR/configs/50-security-monitoring.conf" /etc/rsyslog.d/
    echo "Restored rsyslog security monitoring"
fi

echo "3. Restoring custom scripts..."
if ls "$BACKUP_DIR/scripts/"*.sh 1> /dev/null 2>&1; then
    sudo cp "$BACKUP_DIR/scripts/"*.sh /usr/local/bin/
    sudo chmod +x /usr/local/bin/*.sh
    echo "Restored custom scripts"
fi

echo "4. Restoring services..."

# Enable and configure services
sudo systemctl enable xrdp
sudo systemctl enable lightdm
sudo systemctl enable unattended-upgrades

# Restore cloudflared service if present
if [[ -f "$BACKUP_DIR/services/cloudflared.service" ]]; then
    sudo cp "$BACKUP_DIR/services/cloudflared.service" /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable cloudflared
    echo "Restored cloudflared service"
fi

# Set display manager
echo "/usr/sbin/lightdm" | sudo tee /etc/X11/default-display-manager > /dev/null

echo "5. Configuring firewall..."
sudo ufw --force enable
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from 127.0.0.1 to any port 3389 comment "Local RDP for cloudflared"
sudo ufw allow out 443 comment "HTTPS for cloudflared tunnel"
sudo ufw allow out 7844 comment "Cloudflared tunnel protocol"

echo "6. Setting up monitoring..."
# Add cron jobs if they don't exist
if ! sudo crontab -l | grep -q "monitor-cloudflared.sh"; then
    (sudo crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/monitor-cloudflared.sh") | sudo crontab -
fi

if ! sudo crontab -l | grep -q "monitor-connections.sh"; then
    (sudo crontab -l 2>/dev/null; echo "*/15 * * * * /usr/local/bin/monitor-connections.sh") | sudo crontab -
fi

echo "7. Final system configuration..."
# Restart essential services
sudo systemctl restart rsyslog
sudo systemctl restart xrdp
sudo systemctl restart cloudflared 2>/dev/null || echo "Cloudflared will start on next boot"

echo "=== System Restoration Completed at $(date) ==="
echo ""
echo "IMPORTANT NEXT STEPS:"
echo "1. Verify cloudflared tunnel authentication (if needed)"
echo "2. Test RDP connection through tunnel"
echo "3. Reboot system to ensure all services start correctly"
echo ""
echo "Restoration completed successfully!"