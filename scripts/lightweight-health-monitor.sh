#!/bin/bash

# EliteMini Lightweight Development System Health Monitor
# Optimized for MINIMAL resource usage
# Monitors only critical services with fast execution

LOG_FILE="/home/sunwolf/emini-backup/emini-backup/logs/health-monitor.log"
ALERT_THRESHOLD_DISK=85
ALERT_THRESHOLD_MEMORY=90

# Lightweight logging function
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" >> $LOG_FILE
}

# Quick critical services check (essential for development)
check_critical_services() {
    # Keep-awake service (prevents system sleep)
    if systemctl is-active --quiet keep-awake; then
        log_message "✅ keep-awake: UP"
    else
        log_message "🚨 CRITICAL: keep-awake DOWN - auto-restarting"
        sudo systemctl start keep-awake
        log_message "🔧 keep-awake restarted"
    fi
    
    # RDP service (remote access)
    if systemctl is-active --quiet xrdp; then
        log_message "✅ RDP: UP"
    else
        log_message "🚨 CRITICAL: RDP DOWN - auto-restarting"
        sudo systemctl start xrdp
        log_message "🔧 RDP restarted"
    fi
    
    # Cloudflare tunnel (external access)
    if pgrep cloudflared >/dev/null 2>&1; then
        log_message "✅ Tunnel: UP"
    else
        log_message "🚨 WARNING: Cloudflare tunnel DOWN"
    fi
}

# Quick resource check (minimal processing)
check_resources() {
    # Disk space (fast check)
    DISK_USAGE=$(df / | awk 'NR==2{print $5}' | sed 's/%//')
    if [ "$DISK_USAGE" -gt $ALERT_THRESHOLD_DISK ]; then
        log_message "🚨 WARNING: Disk ${DISK_USAGE}%"
    fi
    
    # Memory usage (fast calculation)
    MEMORY_USAGE=$(free | awk 'NR==2{printf "%.0f", $3/$2*100}')
    if [ "$MEMORY_USAGE" -gt $ALERT_THRESHOLD_MEMORY ]; then
        log_message "🚨 WARNING: Memory ${MEMORY_USAGE}%"
    fi
}

# Network connectivity (essential for development)
check_network() {
    # GitHub connectivity (critical for git operations)
    if timeout 3 ping -c 1 github.com >/dev/null 2>&1; then
        log_message "✅ GitHub: OK"
    else
        log_message "🚨 WARNING: GitHub unreachable"
    fi
}

# Generate health summary (minimal processing)
generate_summary() {
    # Count recent critical alerts only
    CRITICAL_ALERTS=$(tail -n 20 $LOG_FILE 2>/dev/null | grep -c "🚨 CRITICAL")
    CRITICAL_ALERTS=${CRITICAL_ALERTS:-0}
    
    if [ "$CRITICAL_ALERTS" -eq 0 ]; then
        log_message "🎉 STATUS: HEALTHY ($(uptime -p | sed 's/up //'))"
    else
        log_message "⚠️  STATUS: ${CRITICAL_ALERTS} critical alerts"
    fi
}

# Main execution (optimized for speed)
main() {
    check_critical_services
    check_resources  
    check_network
    generate_summary
}

# Execute with minimal overhead
main