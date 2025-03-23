#!/bin/bash
# bkpManager v2.4 - Guaranteed Scan Backup Folder with Deletion of Files within & Permission Manager 
# Version: 2.4 (Nuclear Fix)
# Author: Dhruval Joshi from HostingSpell LLP.


LOG_DIR="/var/log/bkpManager"
mkdir -p "$LOG_DIR"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_FILE="$LOG_DIR/bkpManager-v2.4-$TIMESTAMP.txt"

EXCLUDED_USERS=("root" "nobody" "mysql" "system")
SCAN_PATH="/home"
RESTORE_MODE=0  # Default: DELETE backups

log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

# Backup directories inside main, addon, and subdomains
KNOWN_BACKUP_DIRS=(
    "wp-content/ai1wm-backups"
    "wp-content/updraft"
    "wp-content/backuply"
    "wp-content/backupbuddy_backups"
    "wp-content/backwpup-*"
    "lscache_backups"
    "softaculous_backups"
    "wordpress-backups"
    "ai1wm-backups"
    "backuply"
)

# Function to find backup directories
find_backup_dirs() {
    local user_home="$1"
    local found_dirs=()

    while IFS= read -r site_path; do
        for backup_dir in "${KNOWN_BACKUP_DIRS[@]}"; do
            full_backup_path="$site_path/$backup_dir"
            if [ -d "$full_backup_path" ]; then
                found_dirs+=("$full_backup_path")
            fi
        done
    done < <(find "$user_home" -mindepth 2 -maxdepth 4 -type d -name "wp-content" -exec dirname {} \; 2>/dev/null)

    echo "${found_dirs[@]}"
}

# Function to enforce backup policy
enforce_backup_policy() {
    local username="$1"
    local user_home="$SCAN_PATH/$username"

    [[ " ${EXCLUDED_USERS[*]} " == *" $username "* ]] && return
    [[ ! -d "$user_home" ]] && return

    log "\n🔍 Scanning user: $username"

    local found_dirs
    found_dirs=$(find_backup_dirs "$user_home")

    [[ -z "$found_dirs" ]] && log "✅ No backup directories found for $username." && return

    log "⚠️ Backup directories found under $username:"
    for dir in $found_dirs; do
        [[ "$dir" =~ "/tmp" ]] && continue
        log "   📂 $dir"
    done

    local before_size=$(du -sh "$user_home" 2>/dev/null | awk '{print $1}')
    local total_removed=0

    for dir in $found_dirs; do
        [[ "$dir" =~ "/tmp" ]] && continue

        log "🗂️ Checking files in: $dir"

        # List all backup files before deletion
        ls -lah "$dir" | tee -a "$LOG_FILE"

        # Remove immutable flag if set
        sudo chattr -i "$dir"/* 2>/dev/null

        # Delete backup files (Method 1)
        sudo find "$dir" -type f \( -iname "*.tar*" -o -iname "*.zip" -o -iname "*.bak" -o -iname "*.bkup" -o -iname "*.wpress" -o -iname "*.gz" \) -exec rm -f {} +

        # Verify deletion (Method 2)
        remaining_files=$(find "$dir" -type f \( -iname "*.tar*" -o -iname "*.zip" -o -iname "*.bak" -o -iname "*.bkup" -o -iname "*.wpress" -o -iname "*.gz" \))
        if [[ -z "$remaining_files" ]]; then
            log "   ✅ Backup files deleted in: $dir"
            ((total_removed++))

            # NOW set restrictive permissions **AFTER** deletion
            chmod 0000 "$dir"
            chown root:root "$dir"
            log "   🔒 Restricted: $dir (Permissions: 0000, Owner: root)"
        else
            log "   ❌ Some files could not be deleted in: $dir (Attempting final deletion pass...)"

            # **Final Pass: Try to delete again using "unlink"**
            for file in $remaining_files; do
                sudo unlink "$file"
            done

            # Verify again
            final_remaining_files=$(find "$dir" -type f \( -iname "*.tar*" -o -iname "*.zip" -o -iname "*.bak" -o -iname "*.bkup" -o -iname "*.wpress" -o -iname "*.gz" \))
            if [[ -z "$final_remaining_files" ]]; then
                log "   ✅ Backup files force-deleted in: $dir"
                chmod 0000 "$dir"
                chown root:root "$dir"
                log "   🔒 Restricted: $dir (Permissions: 0000, Owner: root)"
            else
                log "   ❌ Files STILL exist in: $dir. Manual check needed!"
            fi
        fi
    done

    local after_size=$(du -sh "$user_home" 2>/dev/null | awk '{print $1}')
    
    log "🗑️  Removed $total_removed backup files for $username."
    log "📊 Disk usage before: $before_size | After: $after_size\n"
    echo "$username,$total_removed,$before_size,$after_size" >> "$LOG_FILE"
}

# Function to restore permissions
restore_backup_permissions() {
    local username="$1"
    local user_home="$SCAN_PATH/$username"
    
    [[ " ${EXCLUDED_USERS[*]} " == *" $username "* ]] && return
    [[ ! -d "$user_home" ]] && return

    log "\n🔄 Restoring permissions for $username (No files will be deleted)"

    local found_dirs
    found_dirs=$(find_backup_dirs "$user_home")

    [[ -z "$found_dirs" ]] && log "✅ No restricted backup directories found for $username." && return

    for dir in $found_dirs; do
        [[ "$dir" =~ "/tmp" ]] && continue
        if [ -d "$dir" ]; then
            chown -R "$username:$username" "$dir"
            chmod 755 "$dir"
            log "✔️ Restored: $dir (Permissions: 755, Owner: $username)"
        fi
    done
}

# Process arguments
RESTORE_MODE=0
USERNAME=""

for arg in "$@"; do
    case "$arg" in
        -d) RESTORE_MODE=1 ;;  # Restore Mode
        *) USERNAME="$arg" ;;   # cPanel username
    esac
done

# Apply action based on input
if [ -n "$USERNAME" ]; then
    if id "$USERNAME" >/dev/null 2>&1; then
        if [ "$RESTORE_MODE" -eq 1 ]; then
            restore_backup_permissions "$USERNAME"
        else
            enforce_backup_policy "$USERNAME"
        fi
    else
        echo "User $USERNAME not found!"
        exit 1
    fi
else
    if [ "$RESTORE_MODE" -eq 1 ]; then
        log "🚀 Restoring permissions for all cPanel users..."
        for user in $(ls -1 "$SCAN_PATH"); do id "$user" >/dev/null 2>&1 && restore_backup_permissions "$user"; done
    else
        log "🚀 Enforcing backup policies for all cPanel users..."
        for user in $(ls -1 "$SCAN_PATH"); do id "$user" >/dev/null 2>&1 && enforce_backup_policy "$user"; done
    fi
fi
