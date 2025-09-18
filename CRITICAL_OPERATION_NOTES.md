# 🚨 CRITICAL OPERATION NOTES

**⚠️  IMPORTANT: Read before making system changes ⚠️**

---

## 🔴 **CRITICAL: NEVER RESTART XRDP WHILE CONNECTED**

### **⚠️  DISCOVERED ISSUE:**
- **Problem**: Restarting XRDP service while actively connected via RDP causes **immediate disconnection** and **prevents reconnection**
- **Impact**: Requires **physical reboot** of the EliteMini to restore RDP access
- **Risk Level**: **CRITICAL** - Can cause complete remote access lockout

### **🚫 SERVICES TO NEVER RESTART WHILE CONNECTED:**
- `xrdp` - RDP daemon (your current connection)
- `xrdp-sesman` - RDP session manager
- Related RDP services

### **✅ SAFE ALTERNATIVES:**
- **Monitor XRDP**: Check status without restarting
- **Schedule restarts**: Only when physically present
- **Use SSH**: For service management (doesn't disconnect RDP)
- **Health check only**: Monitor but don't auto-heal XRDP while connected

---

## 🛡️ **UPDATED HEALTH MONITORING RULES**

### **Modified Auto-Healing Behavior:**
1. **XRDP Health Check**: Monitor status but **DO NOT** auto-restart
2. **Log Only**: Record XRDP issues for manual intervention
3. **Alternative Access**: Ensure SSH remains available for manual fixes
4. **Physical Access Required**: For XRDP service management

### **Safe Auto-Healing Services:**
- ✅ `keep-awake` - Safe to restart (no connection impact)
- ✅ `ssh.socket` - Safe to restart (doesn't affect RDP)
- ✅ `cloudflared` - Safe to restart (tunnel reconnects automatically)
- ✅ `NetworkManager` - Usually safe (brief network interruption)
- ✅ `UFW` - Safe to enable/restart
- ❌ `xrdp` - **NEVER auto-restart while connected**

---

## 📋 **EMERGENCY RECOVERY PROCEDURES**

### **If RDP Connection Lost:**
1. **Try SSH First**: `ssh sunwolf@192.168.1.173`
2. **Check XRDP Status**: `sudo systemctl status xrdp`
3. **Manual Restart** (only if not connected via RDP):
   ```bash
   sudo systemctl restart xrdp
   sudo systemctl restart xrdp-sesman
   ```
4. **If SSH Also Fails**: Physical reboot required

### **Prevention Checklist:**
- [ ] Never run `sudo systemctl restart xrdp` while connected via RDP
- [ ] Use SSH for system administration when possible
- [ ] Schedule XRDP maintenance during physical access windows
- [ ] Always have alternative access method (SSH) available

---

## 🔧 **MODIFIED HEALTH MONITOR APPROACH**

### **XRDP-Safe Monitoring:**
```bash
# Check XRDP status (safe)
if systemctl is-active --quiet xrdp; then
    log_message "OK" "RDP service: RUNNING"
else
    log_message "CRITICAL" "RDP service DOWN - MANUAL intervention required"
    log_message "WARNING" "DO NOT auto-restart XRDP while connected via RDP"
    # DO NOT auto-restart XRDP
fi
```

### **Connection-Aware Healing:**
- Detect if user is connected via RDP
- Skip XRDP auto-healing if RDP session active
- Provide manual intervention instructions
- Log issues for later resolution

---

## 🎯 **SESSION PERSISTENCE CONFIGURATION**

### **Current XRDP Settings (Applied):**
- `MaxSessions=1` - Single session per user
- `KillDisconnected=false` - Keep sessions alive
- `DisconnectedTimeLimit=0` - No timeout
- `ReconnectSame=1` - Reconnect to existing session

### **Benefits:**
- ✅ Reconnect to same session after disconnection
- ✅ Preserve running applications and open files
- ✅ No need to restart applications after reconnection
- ✅ Seamless work continuation

---

## 📞 **EMERGENCY CONTACT PROCEDURES**

### **If Locked Out:**
1. **Physical Access**: Go to EliteMini directly
2. **Power Cycle**: Unplug and restart if necessary
3. **Check Logs**: Review what caused the lockout
4. **Prevent Recurrence**: Update scripts to avoid the issue

### **Recovery Commands (Physical Access):**
```bash
# Restart all remote access services
sudo systemctl restart xrdp xrdp-sesman
sudo systemctl restart ssh
sudo systemctl restart cloudflared

# Check service status
sudo systemctl status xrdp ssh.socket cloudflared

# View recent logs
sudo journalctl -u xrdp -n 50
```

---

## ✅ **LESSONS LEARNED**

### **Key Takeaways:**
1. **Never restart services you're currently using** for connection
2. **Always have backup access method** (SSH when using RDP)
3. **Test service restarts when physically present** first
4. **Monitor vs. Heal**: Some services should only be monitored, not auto-healed
5. **Connection awareness**: Scripts should detect active connections

### **Updated Script Behavior:**
- Health monitoring: **Enhanced and safer**
- Auto-healing: **Connection-aware and selective**
- Service management: **Conservative approach for critical services**
- Logging: **More detailed for manual intervention guidance**

---

**🔐 This file contains critical operational knowledge for safe system management. Review before making any service-level changes. 🔐**

**Last Updated**: $(date '+%Y-%m-%d %H:%M:%S %Z')  
**Incident**: XRDP restart caused connection lockout requiring physical reboot  
**Resolution**: Updated health monitoring to never auto-restart XRDP while connected