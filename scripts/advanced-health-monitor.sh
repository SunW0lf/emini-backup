#!/bin/bash

# Advanced EliteMini System Health Monitor & Auto-Healer
# Comprehensive monitoring with intelligent healing capabilities
# Runs every 10 minutes with proactive system maintenance

LOG_FILE="/home/sunwolf/emini-backup/emini-backup/logs/advanced-health-monitor.log"
ALERT_THRESHOLD_DISK=85
ALERT_THRESHOLD_MEMORY=90
ALERT_THRESHOLD_CPU=95
ALERT_THRESHOLD_LOAD=10.0

# Healing counters and limits
HEALING_LOG="/home/sunwolf/emini-backup/emini-backup/logs/healing-actions.log"
MAX_HEALING_ATTEMPTS=3

# Advanced logging with severity levels
log_message() {
    local severity="$1"
    local message="$2"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[$timestamp] [$severity] $message" >> "$LOG_FILE"
}

log_healing() {
    local action="$1"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[$timestamp] HEALING: $action" >> "$HEALING_LOG"
}

# Check and heal critical system services
check_and_heal_services() {
    log_message "INFO" "=== ADVANCED SERVICE HEALTH CHECK ==="
    
    # Keep-awake service (system sleep prevention)
    if systemctl is-active --quiet keep-awake; then
        log_message "OK" "keep-awake service: RUNNING"
    else
        log_message "CRITICAL" "keep-awake service DOWN - initiating auto-healing"
        log_healing "Restarting keep-awake service"
        if sudo systemctl start keep-awake && sudo systemctl enable keep-awake; then
            log_message "RECOVERY" "keep-awake service restarted successfully"
        else
            log_message "ERROR" "Failed to restart keep-awake service - manual intervention required"
        fi
    fi
    
    # RDP service (remote access) - CRITICAL: NEVER auto-restart while connected
    if systemctl is-active --quiet xrdp; then
        log_message "OK" "RDP service: RUNNING"
    else
        log_message "CRITICAL" "RDP service DOWN - MANUAL intervention required"
        log_message "WARNING" "XRDP auto-restart DISABLED to prevent connection lockout"
        log_message "INFO" "Use SSH access to manually restart XRDP when safe"
        # DO NOT auto-restart XRDP - can cause connection lockout requiring physical reboot
    fi
    
    # SSH socket (command line access)
    if systemctl is-active --quiet ssh.socket; then
        log_message "OK" "SSH socket: RUNNING"
    else
        log_message "CRITICAL" "SSH socket DOWN - initiating auto-healing"
        log_healing "Restarting SSH socket"
        if sudo systemctl start ssh.socket && sudo systemctl enable ssh.socket; then
            log_message "RECOVERY" "SSH socket restarted successfully"
        else
            log_message "ERROR" "Failed to restart SSH socket - manual intervention required"
        fi
    fi
    
    # Cloudflare tunnel (external access)
    if pgrep cloudflared >/dev/null 2>&1; then
        log_message "OK" "Cloudflare tunnel: RUNNING"
    else
        log_message "WARNING" "Cloudflare tunnel DOWN - attempting restart"
        log_healing "Restarting Cloudflare tunnel"
        if sudo systemctl restart cloudflared; then
            sleep 5
            if pgrep cloudflared >/dev/null 2>&1; then
                log_message "RECOVERY" "Cloudflare tunnel restarted successfully"
            else
                log_message "ERROR" "Cloudflare tunnel restart failed - check configuration"
            fi
        else
            log_message "ERROR" "Failed to restart Cloudflare tunnel service"
        fi
    fi
    
    # Network manager (connectivity)
    if systemctl is-active --quiet NetworkManager; then
        log_message "OK" "NetworkManager: RUNNING"
    else
        log_message "WARNING" "NetworkManager DOWN - attempting restart"
        log_healing "Restarting NetworkManager"
        sudo systemctl restart NetworkManager
    fi
    
    # UFW firewall
    if sudo ufw status | grep -q "Status: active"; then
        log_message "OK" "UFW firewall: ACTIVE"
    else
        log_message "WARNING" "UFW firewall inactive - enabling"
        log_healing "Enabling UFW firewall"
        sudo ufw --force enable
    fi
}

# Advanced resource monitoring with proactive management
check_and_heal_resources() {
    log_message "INFO" "=== ADVANCED RESOURCE HEALTH CHECK ==="
    
    # Disk space monitoring and cleanup
    DISK_USAGE=$(df / | awk 'NR==2{print $5}' | sed 's/%//')
    if [ "$DISK_USAGE" -gt $ALERT_THRESHOLD_DISK ]; then
        log_message "WARNING" "High disk usage: ${DISK_USAGE}% (threshold: ${ALERT_THRESHOLD_DISK}%)"
        log_healing "Initiating disk cleanup procedures"
        
        # Clean package cache
        sudo apt autoremove -y >/dev/null 2>&1
        sudo apt autoclean >/dev/null 2>&1
        
        # Clean old logs
        sudo journalctl --vacuum-time=7d >/dev/null 2>&1
        
        # Clean Docker if available
        if command -v docker >/dev/null 2>&1; then
            sudo docker system prune -f >/dev/null 2>&1
        fi
        
        # Check result
        NEW_DISK_USAGE=$(df / | awk 'NR==2{print $5}' | sed 's/%//')
        CLEANED_SPACE=$((DISK_USAGE - NEW_DISK_USAGE))
        log_message "RECOVERY" "Disk cleanup completed: freed ${CLEANED_SPACE}%, usage now ${NEW_DISK_USAGE}%"
    else
        log_message "OK" "Disk usage: ${DISK_USAGE}% (healthy)"
    fi
    
    # Memory monitoring and management
    MEMORY_USAGE=$(free | awk 'NR==2{printf "%.0f", $3/$2*100}')
    if [ "$MEMORY_USAGE" -gt $ALERT_THRESHOLD_MEMORY ]; then
        log_message "WARNING" "High memory usage: ${MEMORY_USAGE}% (threshold: ${ALERT_THRESHOLD_MEMORY}%)"
        log_healing "Initiating memory optimization"
        
        # Clear memory caches
        sudo sync && echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null
        
        # Check for memory leaks (processes using >1GB)
        HIGH_MEM_PROCS=$(ps aux --sort=-%mem | awk 'NR>1 && $4>10 {print $2, $11}' | head -5)
        if [ -n "$HIGH_MEM_PROCS" ]; then
            log_message "INFO" "High memory processes detected: $HIGH_MEM_PROCS"
        fi
        
        NEW_MEMORY_USAGE=$(free | awk 'NR==2{printf "%.0f", $3/$2*100}')
        log_message "INFO" "Memory usage after optimization: ${NEW_MEMORY_USAGE}%"
    else
        log_message "OK" "Memory usage: ${MEMORY_USAGE}% (healthy)"
    fi
    
    # CPU load monitoring
    LOAD_1MIN=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    LOAD_CHECK=$(echo "$LOAD_1MIN > $ALERT_THRESHOLD_LOAD" | bc -l 2>/dev/null || echo 0)
    if [ "$LOAD_CHECK" = "1" ]; then
        log_message "WARNING" "High CPU load: ${LOAD_1MIN} (threshold: ${ALERT_THRESHOLD_LOAD})"
        
        # Identify high CPU processes
        HIGH_CPU_PROCS=$(ps aux --sort=-%cpu | awk 'NR>1 && $3>50 {print $2, $11}' | head -3)
        if [ -n "$HIGH_CPU_PROCS" ]; then
            log_message "INFO" "High CPU processes: $HIGH_CPU_PROCS"
        fi
    else
        log_message "OK" "CPU load: ${LOAD_1MIN} (16-core system)"
    fi
    
    # Temperature monitoring (if available)
    if command -v sensors >/dev/null 2>&1; then
        CPU_TEMP=$(sensors 2>/dev/null | grep -E "Core|Package|CPU" | awk '{print $3}' | head -1 | sed 's/°C//' | sed 's/+//')
        if [ -n "$CPU_TEMP" ] && [ "$CPU_TEMP" -gt 80 ]; then
            log_message "WARNING" "High CPU temperature: ${CPU_TEMP}°C"
        fi
    fi
}

# Network connectivity and healing
check_and_heal_network() {
    log_message "INFO" "=== NETWORK CONNECTIVITY CHECK ==="
    
    # Primary DNS test (Google)
    if timeout 3 ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        log_message "OK" "Internet connectivity: AVAILABLE"
    else
        log_message "WARNING" "Internet connectivity issues detected"
        log_healing "Attempting network recovery"
        
        # Restart network interface
        INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
        if [ -n "$INTERFACE" ]; then
            sudo ip link set "$INTERFACE" down
            sleep 2
            sudo ip link set "$INTERFACE" up
            sleep 5
        fi
        
        # Test again
        if timeout 3 ping -c 1 8.8.8.8 >/dev/null 2>&1; then
            log_message "RECOVERY" "Network connectivity restored"
        else
            log_message "ERROR" "Network connectivity still impaired"
        fi
    fi
    
    # GitHub connectivity (critical for development)
    if timeout 5 ping -c 1 github.com >/dev/null 2>&1; then
        log_message "OK" "GitHub connectivity: AVAILABLE"
    else
        log_message "WARNING" "GitHub unreachable - may impact development"
    fi
    
    # Local network gateway
    GATEWAY=$(ip route | grep default | awk '{print $3}' | head -1)
    if [ -n "$GATEWAY" ] && timeout 3 ping -c 1 "$GATEWAY" >/dev/null 2>&1; then
        log_message "OK" "Local network gateway: REACHABLE"
    else
        log_message "WARNING" "Local network gateway issues"
    fi
}

# Process and application healing
check_and_heal_processes() {
    log_message "INFO" "=== PROCESS HEALTH CHECK ==="
    
    # Check for zombie processes
    ZOMBIE_COUNT=$(ps aux | awk '$8 ~ /^Z/ {count++} END {print count+0}')
    if [ "$ZOMBIE_COUNT" -gt 5 ]; then
        log_message "WARNING" "High zombie process count: $ZOMBIE_COUNT"
        log_healing "Cleaning zombie processes"
        # Kill parent processes that have zombies
        ps aux | awk '$8 ~ /^Z/ {print $3}' | sort -u | xargs -r kill -TERM 2>/dev/null || true
    fi
    
    # Check for processes consuming excessive resources
    HIGH_MEM_PROC=$(ps aux --sort=-%mem | awk 'NR==2 {if($4>20) print $11 " (" $4 "%)"}')
    if [ -n "$HIGH_MEM_PROC" ]; then
        log_message "INFO" "Highest memory consumer: $HIGH_MEM_PROC"
    fi
    
    # Check for failed systemd units
    FAILED_UNITS=$(systemctl --failed --no-legend | wc -l)
    if [ "$FAILED_UNITS" -gt 0 ]; then
        log_message "WARNING" "Failed systemd units detected: $FAILED_UNITS"
        FAILED_LIST=$(systemctl --failed --no-legend | awk '{print $1}' | head -3)
        log_message "INFO" "Failed units: $FAILED_LIST"
    fi
}

# File system and storage health
check_and_heal_filesystem() {
    log_message "INFO" "=== FILESYSTEM HEALTH CHECK ==="
    
    # Check for read-only filesystems
    RO_FILESYSTEMS=$(mount | grep " ro," | wc -l)
    if [ "$RO_FILESYSTEMS" -gt 0 ]; then
        log_message "WARNING" "Read-only filesystems detected: $RO_FILESYSTEMS"
        mount | grep " ro," | head -3 | while read filesystem; do
            log_message "INFO" "Read-only: $filesystem"
        done
    fi
    
    # Check inode usage
    INODE_USAGE=$(df -i / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$INODE_USAGE" -gt 90 ]; then
        log_message "WARNING" "High inode usage: ${INODE_USAGE}%"
    fi
    
    # Check for file system errors in logs
    FS_ERRORS=$(dmesg | grep -i "error\|warning" | grep -i "ext4\|filesystem" | tail -1)
    if [ -n "$FS_ERRORS" ]; then
        log_message "WARNING" "Filesystem errors in dmesg: $FS_ERRORS"
    fi
}

# Security and access monitoring
check_security_status() {
    log_message "INFO" "=== SECURITY STATUS CHECK ==="
    
    # Check for failed login attempts
    FAILED_LOGINS=$(sudo grep "Failed password" /var/log/auth.log 2>/dev/null | grep "$(date '+%Y-%m-%d %H:')" | wc -l)
    if [ "$FAILED_LOGINS" -gt 5 ]; then
        log_message "WARNING" "High failed login attempts this hour: $FAILED_LOGINS"
    fi
    
    # Check active connections
    ACTIVE_CONNECTIONS=$(who | wc -l)
    if [ "$ACTIVE_CONNECTIONS" -gt 0 ]; then
        log_message "INFO" "Active user sessions: $ACTIVE_CONNECTIONS"
    fi
    
    # Check UFW status
    if ! sudo ufw status | grep -q "Status: active"; then
        log_message "WARNING" "UFW firewall is not active"
        log_healing "Enabling UFW firewall"
        sudo ufw --force enable >/dev/null 2>&1
    fi
}

# Generate comprehensive health summary
generate_health_summary() {
    log_message "INFO" "=== COMPREHENSIVE HEALTH SUMMARY ==="
    
    # Count different types of alerts
    CRITICAL_ALERTS=$(tail -n 100 "$LOG_FILE" 2>/dev/null | grep -c "\[CRITICAL\]")
    CRITICAL_ALERTS=${CRITICAL_ALERTS:-0}
    WARNING_ALERTS=$(tail -n 100 "$LOG_FILE" 2>/dev/null | grep -c "\[WARNING\]")
    WARNING_ALERTS=${WARNING_ALERTS:-0}
    RECOVERY_ACTIONS=$(tail -n 100 "$LOG_FILE" 2>/dev/null | grep -c "\[RECOVERY\]")
    RECOVERY_ACTIONS=${RECOVERY_ACTIONS:-0}
    
    # System uptime and load
    UPTIME_DAYS=$(uptime -p | sed 's/up //')
    CURRENT_LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    
    # Resource summary
    DISK_FREE=$(df -h / | awk 'NR==2{print $4}')
    MEM_AVAILABLE=$(free -h | awk 'NR==2{print $7}')
    
    if [ "$CRITICAL_ALERTS" -eq 0 ] && [ "$WARNING_ALERTS" -eq 0 ]; then
        log_message "OK" "🎉 SYSTEM STATUS: ALL HEALTHY - No issues detected"
        log_message "INFO" "📊 Uptime: $UPTIME_DAYS | Load: $CURRENT_LOAD | Free disk: $DISK_FREE | Available RAM: $MEM_AVAILABLE"
    elif [ "$CRITICAL_ALERTS" -eq 0 ]; then
        log_message "INFO" "⚠️  SYSTEM STATUS: $WARNING_ALERTS warnings detected (no critical issues)"
        log_message "INFO" "🔧 Auto-healing actions taken: $RECOVERY_ACTIONS"
    else
        log_message "WARNING" "🚨 SYSTEM STATUS: $CRITICAL_ALERTS critical alerts, $WARNING_ALERTS warnings"
        log_message "INFO" "🔧 Auto-healing actions taken: $RECOVERY_ACTIONS"
    fi
    
    log_message "INFO" "=================================="
}

# Main health check execution
main() {
    log_message "INFO" "🔍 Starting advanced health monitoring check..."
    
    # Execute all health checks with healing
    check_and_heal_services
    check_and_heal_resources
    check_and_heal_network
    check_and_heal_processes
    check_and_heal_filesystem
    check_security_status
    generate_health_summary
    
    log_message "INFO" "✅ Advanced health monitoring check completed"
    echo "" >> "$LOG_FILE"
}

# Execute main function
main