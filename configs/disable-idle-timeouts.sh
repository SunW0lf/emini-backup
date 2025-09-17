#!/bin/bash
# Script to disable idle timeouts for RDP sessions
# This ensures all RDP users have persistent sessions

# Disable GNOME session idle detection
gsettings set org.gnome.desktop.session idle-delay 0

# Disable screensaver idle activation
gsettings set org.gnome.desktop.screensaver idle-activation-enabled false

# Disable screen locking
gsettings set org.gnome.desktop.screensaver lock-enabled false

# Disable idle dimming
gsettings set org.gnome.settings-daemon.plugins.power idle-dim false

# Disable automatic suspend on AC power (for desktop systems)
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 0

# Set this script to run for all new RDP sessions
echo "Idle timeouts disabled for RDP session"