#!/bin/bash
# Sensible Anti-Sleep Configuration
# Prevents system sleep while preserving emergency power button functionality

echo "=== Configuring Sensible Anti-Sleep Settings ==="

# 1. Mask systemd sleep targets (keep this - prevents accidental sleep)
echo "1. Masking systemd sleep targets..."
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

# 2. Configure logind with SENSIBLE power management
echo "2. Configuring systemd-logind (preserving power button)..."
sudo tee /etc/systemd/logind.conf > /dev/null << 'EOF'
[Login]
# Allow power button for emergency shutdowns/restarts - you need this!
HandlePowerKey=poweroff

# Disable sleep-related keys and actions (the real culprits)
HandleSuspendKey=ignore
HandleHibernateKey=ignore
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore

# Never suspend on idle - this is the main thing causing your RDP disconnects
IdleAction=ignore
IdleActionSec=0

# Keep user sessions alive longer
UserStopDelaySec=10
EOF

# 3. Disable automatic power management services (but not power button handling)
echo "3. Disabling problematic power management services..."
sudo systemctl disable --now power-profiles-daemon 2>/dev/null || true
sudo systemctl mask power-profiles-daemon 2>/dev/null || true

# 4. Configure XFCE power manager to never sleep but allow manual power off
echo "4. Configuring XFCE power management..."
if command -v xfconf-query &> /dev/null; then
    # Disable automatic sleep/blank but keep power button functionality
    xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/blank-on-ac -s 0 --create --type int 2>/dev/null || true
    xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/blank-on-battery -s 0 --create --type int 2>/dev/null || true
    xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-enabled -s false --create --type bool 2>/dev/null || true
    xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/inactivity-on-ac -s 14 --create --type int 2>/dev/null || true
    xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/inactivity-on-battery -s 14 --create --type int 2>/dev/null || true
    xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/lock-screen-suspend-hibernate -s false --create --type bool 2>/dev/null || true
    
    # Keep power button working for shutdown (don't disable logind handling)
    xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/logind-handle-lid-switch -s false --create --type bool 2>/dev/null || true
fi

# 5. Keep the keep-awake service (it's harmless and provides monitoring)
echo "5. Ensuring keep-awake service is running..."
if ! systemctl is-active --quiet keep-awake; then
    sudo tee /etc/systemd/system/keep-awake.service > /dev/null << 'EOF'
[Unit]
Description=Keep System Awake (Anti-Sleep Monitor)
After=multi-user.target

[Service]
Type=simple
ExecStart=/bin/bash -c 'while true; do echo "$(date): System awake - Power button still works for emergency shutdown" >> /var/log/keep-awake.log; sleep 300; done'
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl enable keep-awake.service
    sudo systemctl start keep-awake.service
fi

# 6. Restart logind to apply changes
echo "6. Restarting systemd-logind..."
sudo systemctl restart systemd-logind

echo ""
echo "=== Sensible Anti-Sleep Configuration Complete ==="
echo ""
echo "✅ WHAT'S PROTECTED:"
echo "   - System will NEVER auto-sleep/suspend"
echo "   - RDP sessions will remain persistent"
echo "   - Screen stays on indefinitely"
echo "   - Lid closing has no effect"
echo ""
echo "🔌 WHAT STILL WORKS:"
echo "   - Power button = immediate shutdown (emergency use)"
echo "   - Manual shutdown/reboot commands"
echo "   - All normal system control"
echo ""
echo "📊 MONITORING:"
echo "   systemctl status keep-awake"
echo "   tail -f /var/log/keep-awake.log"
echo ""
echo "💡 Power Button Behavior:"
echo "   Short press = Shutdown (for when you brick things!)"
echo "   Long press = Hardware power off (emergency)"