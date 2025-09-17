#!/bin/bash
# Cloudflared tunnel monitoring script
# Logs tunnel status and connection issues

LOG_FILE="/var/log/cloudflared-monitor.log"
TUNNEL_ID="4c64485c-f64b-4a84-88c0-797f505cb4a3"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Check if cloudflared service is running
if ! systemctl is-active --quiet cloudflared; then
    log_message "ALERT: cloudflared service is not running"
    systemctl status cloudflared >> "$LOG_FILE" 2>&1
    exit 1
fi

# Check tunnel connections
CONNECTIONS=$(cloudflared tunnel info "$TUNNEL_ID" 2>/dev/null | grep -c "CONNECTOR ID")
if [ "$CONNECTIONS" -eq 0 ]; then
    log_message "WARNING: No active tunnel connections found"
else
    log_message "INFO: $CONNECTIONS active tunnel connections"
fi

# Check for recent errors in cloudflared logs
RECENT_ERRORS=$(journalctl -u cloudflared --since "5 minutes ago" | grep -c "ERR\|ERROR\|FATAL")
if [ "$RECENT_ERRORS" -gt 0 ]; then
    log_message "WARNING: $RECENT_ERRORS errors in cloudflared logs in last 5 minutes"
    journalctl -u cloudflared --since "5 minutes ago" | grep "ERR\|ERROR\|FATAL" >> "$LOG_FILE"
fi

log_message "INFO: Monitoring check completed - Service OK"