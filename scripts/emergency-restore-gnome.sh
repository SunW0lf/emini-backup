#!/bin/bash
# Emergency restoration script if XFCE RDP fails

echo "=== EMERGENCY GNOME RESTORATION SCRIPT ==="
echo "This will restore GNOME desktop for RDP access"
read -p "Do you want to continue? (y/N): " confirm

if [[ $confirm != [yY] ]]; then
    echo "Aborted."
    exit 1
fi

# Install minimal GNOME
sudo apt update
sudo apt install -y ubuntu-desktop-minimal gdm3

# Remove XFCE if needed
sudo apt purge -y xfce4 xfce4-goodies

# Set GDM as default
echo "/usr/sbin/gdm3" | sudo tee /etc/X11/default-display-manager

# Restore original sesman.ini
sudo cp /etc/xrdp/sesman.ini.orig /etc/xrdp/sesman.ini 2>/dev/null || echo "No backup found"

# Enable and start GDM
sudo systemctl enable gdm3
sudo systemctl disable lightdm
sudo systemctl restart xrdp

echo "GNOME restoration complete. System will reboot in 10 seconds..."
sleep 10
sudo reboot