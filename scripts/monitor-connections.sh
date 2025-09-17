#!/bin/bash
# Connection pattern monitoring script
# Monitors for unusual RDP connection patterns and failed attempts

LOG_FILE="/var/log/connection-monitor.log"
ALERT_LOG="/var/log/security-alerts.log"
RDP_LOG="/var/log/rdp-access.log"
AUTH_LOG="/var/log/auth-failures.log"

# Thresholds
MAX_FAILED_ATTEMPTS=3
MAX_CONNECTIONS_PER_HOUR=10
MONITOR_WINDOW_MINUTES=60

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

alert_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - SECURITY ALERT: $1" >> "$ALERT_LOG"
    log_message "ALERT: $1"
}

# Check for excessive failed login attempts
if [ -f "$AUTH_LOG" ]; then
    FAILED_ATTEMPTS=$(tail -n 100 "$AUTH_LOG" | grep "$(date '+%Y-%m-%d %H:')" | wc -l)
    if [ "$FAILED_ATTEMPTS" -gt "$MAX_FAILED_ATTEMPTS" ]; then
        alert_message "Excessive failed login attempts detected: $FAILED_ATTEMPTS in last hour"
    fi
fi

# Check for unusual RDP connection patterns
if [ -f "$RDP_LOG" ]; then
    # Count successful logins in the last hour
    CURRENT_HOUR=$(date '+%Y-%m-%d %H:')
    RDP_CONNECTIONS=$(grep "login successful" "$RDP_LOG" | grep "$CURRENT_HOUR" | wc -l)
    
    if [ "$RDP_CONNECTIONS" -gt "$MAX_CONNECTIONS_PER_HOUR" ]; then
        alert_message "Excessive RDP connections detected: $RDP_CONNECTIONS in last hour"
    fi
    
    # Check for connections outside normal hours (example: outside 6 AM - 11 PM)
    CURRENT_HOUR_NUM=$(date '+%H')
    if [ "$CURRENT_HOUR_NUM" -lt 6 ] || [ "$CURRENT_HOUR_NUM" -gt 23 ]; then
        NIGHT_CONNECTIONS=$(grep "login successful" "$RDP_LOG" | grep "$CURRENT_HOUR" | wc -l)
        if [ "$NIGHT_CONNECTIONS" -gt 0 ]; then
            alert_message "RDP connection detected during unusual hours: $NIGHT_CONNECTIONS connections at $(date '+%H:%M')"
        fi
    fi
fi

# Check system resource usage
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
MEMORY_USAGE=$(free | grep Mem | awk '{printf "%.1f", ($3/$2) * 100.0}')

if (( $(echo "$CPU_USAGE > 80" | bc -l) )); then
    alert_message "High CPU usage detected: ${CPU_USAGE}%"
fi

if (( $(echo "$MEMORY_USAGE > 90" | bc -l) )); then
    alert_message "High memory usage detected: ${MEMORY_USAGE}%"
fi

log_message "Connection monitoring completed - CPU: ${CPU_USAGE}%, Memory: ${MEMORY_USAGE}%"