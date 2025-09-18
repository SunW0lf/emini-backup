#!/bin/bash

# EliteMini Development System Health Monitor
# Ensures critical development services stay healthy
# Run every 5 minutes via cron

LOG_FILE="/var/log/dev-health-monitor.log"
ALERT_THRESHOLD_DISK=85
ALERT_THRESHOLD_MEMORY=90

log_message() {
    echo "$(date): $1" | sudo tee -a $LOG_FILE
}

check_critical_services() {
    log_message "=== SERVICE HEALTH CHECK ==="
    
    # Keep-awake service (prevents sleep/suspend)
    if systemctl is-active --quiet keep-awake; then
        log_message "✅ keep-awake service: RUNNING"
    else
        log_message "🚨 CRITICAL: keep-awake service DOWN - system may sleep!"
        sudo systemctl start keep-awake
    fi
    
    # RDP service (remote access)
    if systemctl is-active --quiet xrdp; then
        log_message "✅ RDP service: RUNNING"
    else
        log_message "🚨 CRITICAL: RDP service DOWN - remote access lost!"
        sudo systemctl start xrdp
    fi
    
    # Cloudflare tunnel (external access)
    if pgrep cloudflared >/dev/null; then
        log_message "✅ Cloudflare tunnel: RUNNING"
    else
        log_message "🚨 WARNING: Cloudflare tunnel DOWN - external access lost!"
    fi
    
    # Docker monitoring stack
    if sudo docker ps --format "table {{.Names}}" | grep -q grafana; then
        log_message "✅ Monitoring stack: RUNNING"
    else
        log_message "🚨 WARNING: Monitoring stack DOWN"
    fi
}

check_resources() {
    log_message "=== RESOURCE HEALTH CHECK ==="
    
    # Disk space check
    DISK_USAGE=$(df / | awk 'NR==2{print $5}' | sed 's/%//')
    if [ "$DISK_USAGE" -gt $ALERT_THRESHOLD_DISK ]; then
        log_message "🚨 WARNING: Disk usage ${DISK_USAGE}% (threshold: ${ALERT_THRESHOLD_DISK}%)"
    else
        log_message "✅ Disk usage: ${DISK_USAGE}% (healthy)"
    fi
    
    # Memory usage check
    MEMORY_USAGE=$(free | awk 'NR==2{printf "%.0f", $3/$2*100}')
    if [ "$MEMORY_USAGE" -gt $ALERT_THRESHOLD_MEMORY ]; then
        log_message "🚨 WARNING: Memory usage ${MEMORY_USAGE}% (threshold: ${ALERT_THRESHOLD_MEMORY}%)"
    else
        log_message "✅ Memory usage: ${MEMORY_USAGE}% (healthy)"
    fi
    
    # Load average check
    LOAD_1MIN=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    log_message "✅ Load average: ${LOAD_1MIN} (16-core system)"
}

check_development_environment() {
    log_message "=== DEVELOPMENT ENVIRONMENT CHECK ==="
    
    # Git configuration
    if git config --global user.name >/dev/null 2>&1; then
        log_message "✅ Git: Configured"
    else
        log_message "🚨 WARNING: Git not configured"
    fi
    
    # Warp terminal installation
    if dpkg -l | grep -q warp-terminal; then
        log_message "✅ Warp Terminal: Installed"
    else
        log_message "🚨 WARNING: Warp Terminal not found"
    fi
    
    # Home directory accessibility
    if [ -w /home/sunwolf ]; then
        log_message "✅ Home directory: Accessible"
    else
        log_message "🚨 CRITICAL: Home directory access issue"
    fi
}

check_network_connectivity() {
    log_message "=== NETWORK CONNECTIVITY CHECK ==="
    
    # GitHub connectivity (for development)
    if ping -c 1 github.com >/dev/null 2>&1; then
        log_message "✅ GitHub connectivity: OK"
    else
        log_message "🚨 WARNING: GitHub unreachable"
    fi
    
    # Local network connectivity
    if ping -c 1 192.168.1.1 >/dev/null 2>&1; then
        log_message "✅ Local network: OK"
    else
        log_message "🚨 WARNING: Local network issues"
    fi
}

generate_summary() {
    log_message "=== HEALTH SUMMARY ==="
    
    # Count recent alerts
    RECENT_ALERTS=$(sudo tail -n 50 $LOG_FILE | grep -c "🚨")
    
    if [ "$RECENT_ALERTS" -eq 0 ]; then
        log_message "🎉 SYSTEM STATUS: ALL HEALTHY - Development environment optimal!"
    else
        log_message "⚠️  SYSTEM STATUS: ${RECENT_ALERTS} recent alerts - Review logs"
    fi
    
    # System uptime
    UPTIME=$(uptime -p)
    log_message "🕒 System uptime: $UPTIME"
    
    log_message "=================================="
}

main() {
    log_message "Starting health monitor check..."
    
    check_critical_services
    check_resources
    check_development_environment
    check_network_connectivity
    generate_summary
    
    log_message "Health monitor check completed."
    echo ""
}

# Execute main function
main