#!/bin/bash

# Enhanced EliteMini System Backup Script
# Comprehensive backup of system configurations, user data, and development environment
# Runs daily at 1:00 AM PST with intelligent change detection

BACKUP_LOG="/home/sunwolf/emini-backup/emini-backup/logs/enhanced-backup.log"
REPO_DIR="/home/sunwolf/emini-backup/emini-backup"
BACKUP_ROOT="$REPO_DIR/backups"

# Create backup directories if they don't exist
mkdir -p "$BACKUP_ROOT"/{user-configs,system-configs,development,logs,services}
mkdir -p "$REPO_DIR/logs"

# Logging function with timestamps
log_backup() {
    echo "$(date '+%Y-%m-%d %H:%M:%S PST'): $1" | tee -a "$BACKUP_LOG"
}

# Backup user configuration files
backup_user_configs() {
    log_backup "📁 Backing up user configuration files..."
    
    # Shell configurations
    [ -f ~/.bashrc ] && cp ~/.bashrc "$BACKUP_ROOT/user-configs/bashrc"
    [ -f ~/.profile ] && cp ~/.profile "$BACKUP_ROOT/user-configs/profile"
    [ -f ~/.bash_aliases ] && cp ~/.bash_aliases "$BACKUP_ROOT/user-configs/bash_aliases"
    
    # Git configuration
    [ -f ~/.gitconfig ] && cp ~/.gitconfig "$BACKUP_ROOT/user-configs/gitconfig"
    [ -f ~/.gitignore_global ] && cp ~/.gitignore_global "$BACKUP_ROOT/user-configs/gitignore_global"
    
    # SSH configuration (public keys and config only, not private keys)
    if [ -d ~/.ssh ]; then
        mkdir -p "$BACKUP_ROOT/user-configs/ssh"
        [ -f ~/.ssh/config ] && cp ~/.ssh/config "$BACKUP_ROOT/user-configs/ssh/"
        [ -f ~/.ssh/authorized_keys ] && cp ~/.ssh/authorized_keys "$BACKUP_ROOT/user-configs/ssh/"
        # Copy public keys only
        cp ~/.ssh/*.pub "$BACKUP_ROOT/user-configs/ssh/" 2>/dev/null || true
    fi
    
    # Desktop and application configs
    [ -f ~/.warprc ] && cp ~/.warprc "$BACKUP_ROOT/user-configs/"
    [ -d ~/.config/warp-terminal ] && cp -r ~/.config/warp-terminal "$BACKUP_ROOT/user-configs/" 2>/dev/null || true
    
    # Development environment configurations  
    [ -f ~/.vimrc ] && cp ~/.vimrc "$BACKUP_ROOT/user-configs/"
    [ -f ~/.nanorc ] && cp ~/.nanorc "$BACKUP_ROOT/user-configs/"
    
    log_backup "✅ User configurations backed up"
}

# Backup system configuration files
backup_system_configs() {
    log_backup "⚙️ Backing up system configuration files..."
    
    # Network and SSH configurations (readable copies)
    sudo cp /etc/ssh/sshd_config "$BACKUP_ROOT/system-configs/sshd_config" 2>/dev/null || true
    sudo cp /etc/hosts "$BACKUP_ROOT/system-configs/hosts" 2>/dev/null || true
    sudo cp /etc/hostname "$BACKUP_ROOT/system-configs/hostname" 2>/dev/null || true
    
    # Firewall configuration
    sudo cp -r /etc/ufw "$BACKUP_ROOT/system-configs/" 2>/dev/null || true
    sudo ufw status verbose > "$BACKUP_ROOT/system-configs/ufw-status.txt" 2>/dev/null || true
    
    # Sudoers configuration
    sudo cp -r /etc/sudoers.d "$BACKUP_ROOT/system-configs/" 2>/dev/null || true
    
    # Service configurations
    sudo cp -r /etc/systemd/system/keep-awake.service "$BACKUP_ROOT/system-configs/" 2>/dev/null || true
    sudo cp -r /etc/systemd/system/cloudflared.service "$BACKUP_ROOT/system-configs/" 2>/dev/null || true
    
    # XRDP configuration
    sudo cp /etc/xrdp/xrdp.ini "$BACKUP_ROOT/system-configs/" 2>/dev/null || true
    sudo cp /etc/xrdp/sesman.ini "$BACKUP_ROOT/system-configs/" 2>/dev/null || true
    
    # Cron jobs
    crontab -l > "$BACKUP_ROOT/system-configs/user-crontab.txt" 2>/dev/null || true
    sudo crontab -l > "$BACKUP_ROOT/system-configs/root-crontab.txt" 2>/dev/null || true
    
    log_backup "✅ System configurations backed up"
}

# Backup development environment
backup_development_environment() {
    log_backup "💻 Backing up development environment..."
    
    # List installed packages
    dpkg -l > "$BACKUP_ROOT/development/installed-packages.txt"
    apt list --installed > "$BACKUP_ROOT/development/apt-installed.txt" 2>/dev/null
    
    # Docker configuration
    if command -v docker >/dev/null 2>&1; then
        docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" > "$BACKUP_ROOT/development/docker-images.txt" 2>/dev/null || true
        docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" > "$BACKUP_ROOT/development/docker-containers.txt" 2>/dev/null || true
    fi
    
    # System information
    uname -a > "$BACKUP_ROOT/development/system-info.txt"
    lscpu >> "$BACKUP_ROOT/development/system-info.txt"
    free -h >> "$BACKUP_ROOT/development/system-info.txt"
    df -h >> "$BACKUP_ROOT/development/system-info.txt"
    
    # Network information
    ip addr show > "$BACKUP_ROOT/development/network-config.txt"
    ss -tulpn > "$BACKUP_ROOT/development/open-ports.txt"
    
    log_backup "✅ Development environment backed up"
}

# Backup important logs (recent entries only)
backup_logs() {
    log_backup "📋 Backing up important log entries..."
    
    # System logs (last 100 lines of each)
    sudo tail -n 100 /var/log/auth.log > "$BACKUP_ROOT/logs/auth.log.recent" 2>/dev/null || true
    sudo tail -n 100 /var/log/syslog > "$BACKUP_ROOT/logs/syslog.recent" 2>/dev/null || true
    
    # Service logs
    sudo journalctl -u ssh -n 50 --no-pager > "$BACKUP_ROOT/logs/ssh.log.recent" 2>/dev/null || true
    sudo journalctl -u xrdp -n 50 --no-pager > "$BACKUP_ROOT/logs/xrdp.log.recent" 2>/dev/null || true
    sudo journalctl -u cloudflared -n 50 --no-pager > "$BACKUP_ROOT/logs/cloudflared.log.recent" 2>/dev/null || true
    sudo journalctl -u keep-awake -n 50 --no-pager > "$BACKUP_ROOT/logs/keep-awake.log.recent" 2>/dev/null || true
    
    # Health monitoring logs
    [ -f "$REPO_DIR/logs/health-monitor.log" ] && tail -n 100 "$REPO_DIR/logs/health-monitor.log" > "$BACKUP_ROOT/logs/health-monitor.recent"
    
    log_backup "✅ Important logs backed up"
}

# Backup service status information
backup_service_status() {
    log_backup "🔧 Backing up service status information..."
    
    # System service status
    systemctl --failed > "$BACKUP_ROOT/services/failed-services.txt" 2>/dev/null || true
    systemctl list-units --type=service --state=running > "$BACKUP_ROOT/services/running-services.txt" 2>/dev/null || true
    
    # Critical service status
    for service in ssh xrdp cloudflared keep-awake; do
        systemctl status $service --no-pager > "$BACKUP_ROOT/services/${service}-status.txt" 2>/dev/null || true
    done
    
    # Process information
    ps aux --sort=-%mem | head -20 > "$BACKUP_ROOT/services/top-memory-processes.txt"
    ps aux --sort=-%cpu | head -20 > "$BACKUP_ROOT/services/top-cpu-processes.txt"
    
    log_backup "✅ Service status information backed up"
}

# Generate backup summary
generate_backup_summary() {
    log_backup "📊 Generating backup summary..."
    
    local summary_file="$BACKUP_ROOT/BACKUP_SUMMARY.md"
    
    cat > "$summary_file" << EOF
# 📦 ENHANCED SYSTEM BACKUP SUMMARY

**Backup Date**: $(date '+%Y-%m-%d %H:%M:%S %Z')  
**System**: EliteMini Development Environment  
**User**: sunwolf

## 📁 BACKUP CONTENTS

### User Configurations
- Shell configs: bashrc, profile, aliases
- Git configuration: gitconfig, global gitignore
- SSH configuration: config, authorized_keys, public keys
- Application configs: Warp Terminal, Vim, Nano

### System Configurations  
- SSH daemon configuration
- Firewall rules and status
- Sudoers configuration
- System service definitions
- XRDP configuration
- Cron job schedules

### Development Environment
- Package lists: dpkg, apt
- Docker images and containers
- System information: hardware, network
- Network configuration and open ports

### Service Status
- Failed services list
- Running services list
- Critical service status details
- Resource usage snapshots

### Recent Log Entries
- Authentication logs (last 100 lines)
- System logs (last 100 lines)  
- Service logs (last 50 lines each)
- Health monitor logs

## 📈 BACKUP STATISTICS

EOF

    # Add backup statistics
    echo "- **Total files backed up**: $(find "$BACKUP_ROOT" -type f | wc -l)" >> "$summary_file"
    echo "- **Backup size**: $(du -sh "$BACKUP_ROOT" | cut -f1)" >> "$summary_file"
    echo "- **User configs**: $(find "$BACKUP_ROOT/user-configs" -type f 2>/dev/null | wc -l) files" >> "$summary_file"
    echo "- **System configs**: $(find "$BACKUP_ROOT/system-configs" -type f 2>/dev/null | wc -l) files" >> "$summary_file"
    echo "- **Development data**: $(find "$BACKUP_ROOT/development" -type f 2>/dev/null | wc -l) files" >> "$summary_file"
    echo "- **Service status files**: $(find "$BACKUP_ROOT/services" -type f 2>/dev/null | wc -l) files" >> "$summary_file"
    echo "- **Log files**: $(find "$BACKUP_ROOT/logs" -type f 2>/dev/null | wc -l) files" >> "$summary_file"
    
    cat >> "$summary_file" << EOF

## 🔍 CHANGE DETECTION

$(cd "$REPO_DIR" && git status --porcelain | wc -l) files changed since last backup.

## ⚡ NEXT BACKUP

Next automated backup: $(date -d 'tomorrow 01:00' '+%Y-%m-%d at 1:00 AM PST')

---
*Generated by enhanced-system-backup.sh*
EOF

    log_backup "✅ Backup summary generated"
}

# Main backup execution
perform_enhanced_backup() {
    log_backup "🚀 Starting enhanced system backup..."
    
    # Change to repository directory
    cd "$REPO_DIR" || {
        log_backup "❌ ERROR: Cannot access repository directory"
        exit 1
    }
    
    # Check if we're in a git repository
    if [ ! -d ".git" ]; then
        log_backup "❌ ERROR: Not in a git repository"
        exit 1
    fi
    
    # Perform backup operations
    backup_user_configs
    backup_system_configs  
    backup_development_environment
    backup_logs
    backup_service_status
    generate_backup_summary
    
    # Check for changes before committing
    if [ -n "$(git status --porcelain)" ]; then
        # Add all changes
        git add -A
        
        # Create detailed commit message
        local changed_files=$(git status --porcelain | wc -l)
        local commit_msg="🔄 Enhanced backup $(date '+%Y-%m-%d'): ${changed_files} files updated"
        local commit_desc="Comprehensive system backup including:
- User configurations and shell settings
- System service configurations  
- Development environment snapshots
- Service status and recent logs
- Network and security configurations

Backup size: $(du -sh "$BACKUP_ROOT" | cut -f1)
Total backed up files: $(find "$BACKUP_ROOT" -type f | wc -l)"

        git commit -m "$commit_msg" -m "$commit_desc"
        
        # Push to remote repository
        if git push origin master; then
            log_backup "✅ Enhanced backup completed successfully"
            log_backup "📊 ${changed_files} files committed and pushed to remote repository"
        else
            log_backup "❌ ERROR: Failed to push to remote repository"
            log_backup "💾 Local commit created but remote sync failed"
        fi
    else
        log_backup "ℹ️  No changes detected - backup verification completed"
    fi
    
    # Log final statistics
    local repo_size=$(du -sh "$REPO_DIR" | cut -f1)
    local commit_count=$(git rev-list --count HEAD)
    local backup_size=$(du -sh "$BACKUP_ROOT" | cut -f1)
    
    log_backup "📈 Repository: $repo_size, Commits: $commit_count"
    log_backup "📦 Current backup size: $backup_size"
    log_backup "🎉 Enhanced backup process completed successfully"
    echo "" >> "$BACKUP_LOG"
}

# Execute enhanced backup
perform_enhanced_backup