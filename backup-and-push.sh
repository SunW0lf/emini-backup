#!/bin/bash
# Automated backup and Git push script

set -e

echo "=== IMMOVABLE-WITNESS Automated Backup ==="
echo "$(date)"
echo ""

# Run system backup
echo "1. Running system backup..."
./backup-system.sh

echo ""
echo "2. Committing to Git..."

# Add non-sensitive files
git add backup-system.sh restore-system.sh backup-and-push.sh
git add configs/xrdp.ini configs/sesman.ini configs/user-xsession
git add configs/50unattended-upgrades configs/50-security-monitoring.conf configs/99-security-timeout
git add services/ packages/ scripts/

# Commit with timestamp
git commit -m "System backup $(date '+%Y-%m-%d %H:%M')" || echo "No changes to commit"

echo ""
echo "3. Pushing to GitHub..."
echo "Note: You'll need to authenticate with GitHub token or SSH key"

# Push to remote (requires authentication)
git push origin main

echo ""
echo "=== Backup Complete ==="
echo "Repository: https://github.com/SunW0lf/emini-backup"
echo "Local backup: $(pwd)"