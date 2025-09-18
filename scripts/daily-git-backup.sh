#!/bin/bash

# EliteMini Daily Git Backup - 1:00 AM PST
# Backs up system configuration and development environment
# Runs once daily for realistic change tracking

BACKUP_LOG="/var/log/git-backup.log"
REPO_DIR="/home/sunwolf/emini-backup/emini-backup"

# Logging function
log_backup() {
    echo "$(date '+%Y-%m-%d %H:%M:%S PST'): $1" >> $BACKUP_LOG
}

# Main backup function
perform_backup() {
    log_backup "Starting daily system backup..."
    
    # Change to repository directory
    cd $REPO_DIR
    
    # Check if we're in a git repository
    if [ ! -d ".git" ]; then
        log_backup "❌ ERROR: Not a git repository"
        exit 1
    fi
    
    # Check for changes before committing
    if [ -n "$(git status --porcelain)" ]; then
        # Add all changes
        git add -A
        
        # Create commit with date and summary
        COMMIT_MSG="Daily backup $(date '+%Y-%m-%d'): System configuration and health monitoring updates"
        git commit -m "$COMMIT_MSG"
        
        # Push to remote repository
        if git push origin master; then
            log_backup "✅ Backup completed successfully"
            log_backup "📊 Changes committed and pushed to remote repository"
        else
            log_backup "❌ ERROR: Failed to push to remote repository"
            log_backup "💾 Local commit created but remote sync failed"
        fi
    else
        log_backup "ℹ️  No changes detected - backup skipped"
    fi
    
    # Log repository status
    REPO_SIZE=$(du -sh $REPO_DIR | cut -f1)
    COMMIT_COUNT=$(git rev-list --count HEAD)
    log_backup "📈 Repository: $REPO_SIZE, Commits: $COMMIT_COUNT"
    
    log_backup "Daily backup process completed"
    echo "" >> $BACKUP_LOG
}

# Execute backup
perform_backup