#!/bin/bash
# Comprehensive script to disable ALL sleep/suspend functionality
# For server systems that should never sleep

echo "=== Disabling ALL Sleep/Suspend Functionality ==="

# 1. Mask systemd sleep targets
echo "1. Masking systemd sleep targets..."
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

# 2. Configure logind to ignore all power events
echo "2. Configuring systemd-logind..."
sudo tee /etc/systemd/logind.conf > /dev/null << 'EOF'
[Login]
# Disable all suspend/sleep functionality for server use
HandlePowerKey=ignore
HandleSuspendKey=ignore
HandleHibernateKey=ignore
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore

# Never suspend on idle
IdleAction=ignore
IdleActionSec=0

# Never auto-suspend
UserStopDelaySec=10
EOF

# 3. Disable power management services
echo "3. Disabling power management services..."
sudo systemctl disable --now power-profiles-daemon 2>/dev/null || true
sudo systemctl mask power-profiles-daemon 2>/dev/null || true

# 4. Configure XFCE power manager (if running)
echo "4. Configuring XFCE power management..."
if command -v xfconf-query &> /dev/null; then
    # Disable all power management features
    xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/blank-on-ac -s 0 --create --type int 2>/dev/null || true
    xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/blank-on-battery -s 0 --create --type int 2>/dev/null || true
    xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-enabled -s false --create --type bool 2>/dev/null || true
    xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/inactivity-on-ac -s 14 --create --type int 2>/dev/null || true
    xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/inactivity-on-battery -s 14 --create --type int 2>/dev/null || true
    xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/lock-screen-suspend-hibernate -s false --create --type bool 2>/dev/null || true
    xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/logind-handle-lid-switch -s false --create --type bool 2>/dev/null || true
fi

# 5. Set kernel parameters to prevent suspend
echo "5. Setting kernel parameters..."
echo 'GRUB_CMDLINE_LINUX_DEFAULT="$GRUB_CMDLINE_LINUX_DEFAULT acpi=off apm=off"' | sudo tee -a /etc/default/grub > /dev/null || true

# 6. Create caffeine-like keep-awake service
echo "6. Creating keep-awake service..."
sudo tee /etc/systemd/system/keep-awake.service > /dev/null << 'EOF'
[Unit]
Description=Keep System Awake
After=multi-user.target

[Service]
Type=simple
ExecStart=/bin/bash -c 'while true; do echo "$(date): System awake" >> /var/log/keep-awake.log; sleep 300; done'
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable keep-awake.service
sudo systemctl start keep-awake.service

# 7. Restart logind to apply changes
echo "7. Restarting systemd-logind..."
sudo systemctl restart systemd-logind

echo ""
echo "=== Sleep/Suspend Disabled Successfully ==="
echo "The system will now:"
echo "- Never automatically suspend or hibernate"
echo "- Ignore power button, lid, and suspend keys"
echo "- Keep display active indefinitely"
echo "- Run a keep-awake service every 5 minutes"
echo ""
echo "Check status with:"
echo "  systemctl status keep-awake"
echo "  tail -f /var/log/keep-awake.log"