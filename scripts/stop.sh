#!/usr/bin/env bash
#
# stop.sh - Safely stop Agents-Mobile and cleanup resources
#
# This script:
#   1. Terminates running agents/processes
#   2. Unmounts chroot filesystems (if applicable)
#   3. Cleans up temporary files
#   4. Saves state for next session

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
CHROOT_DIR="${AGENTS_MOBILE_CHROOT:-/data/local/mnt/arch}"
AGENTS_MOBILE_ROOT="${AGENTS_MOBILE_ROOT:-${HOME}/.agents-mobile}"
LOG_FILE="${AGENTS_MOBILE_ROOT}/logs/stop.log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Logging function
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

log "${BLUE}═══════════════════════════════════════════${NC}"
log "${BLUE}  Stopping Agents-Mobile...${NC}"
log "${BLUE}═══════════════════════════════════════════${NC}"

# Detect environment
detect_env() {
    if [[ -n "${TERMUX_VERSION:-}" ]]; then
        if [[ -d "$CHROOT_DIR" ]] && [[ $EUID -eq 0 ]]; then
            ENV="termux-chroot"
        elif command -v proot-distro &>/dev/null; then
            ENV="termux-proot"
        else
            ENV="termux-native"
        fi
    else
        ENV="desktop"
    fi
    
    log "${BLUE}Environment: $ENV${NC}"
}

# Kill running Bun processes
kill_bun_processes() {
    log "${BLUE}[1/5] Checking for Bun processes...${NC}"
    
    if pgrep -f "bun" >/dev/null 2>&1; then
        log "${YELLOW}⚠ Found running Bun processes${NC}"
        
        # List processes
        pgrep -af "bun" | while read -r line; do
            log "  - $line"
        done
        
        # Graceful shutdown (SIGTERM)
        log "${BLUE}Sending SIGTERM...${NC}"
        pkill -TERM -f "bun" 2>/dev/null || true
        sleep 2
        
        # Force kill if still running (SIGKILL)
        if pgrep -f "bun" >/dev/null 2>&1; then
            log "${YELLOW}⚠ Some processes didn't exit, forcing...${NC}"
            pkill -KILL -f "bun" 2>/dev/null || true
        fi
        
        log "${GREEN}✓ Bun processes stopped${NC}"
    else
        log "${GREEN}✓ No Bun processes running${NC}"
    fi
}

# Unmount chroot filesystems
unmount_chroot() {
    if [[ "$ENV" != "termux-chroot" ]]; then
        log "${BLUE}[2/5] Skipping chroot unmount (not applicable)${NC}"
        return
    fi
    
    log "${BLUE}[2/5] Unmounting chroot filesystems...${NC}"
    
    if [[ ! -d "$CHROOT_DIR" ]]; then
        log "${YELLOW}⚠ Chroot directory not found${NC}"
        return
    fi
    
    # Unmount in reverse order (most nested first)
    MOUNT_POINTS=(
        "$CHROOT_DIR/mnt/termux"
        "$CHROOT_DIR/dev/shm"
        "$CHROOT_DIR/dev/pts"
        "$CHROOT_DIR/dev"
        "$CHROOT_DIR/sys"
        "$CHROOT_DIR/proc"
    )
    
    for mount_point in "${MOUNT_POINTS[@]}"; do
        if mountpoint -q "$mount_point" 2>/dev/null; then
            log "${BLUE}Unmounting $mount_point...${NC}"
            if umount "$mount_point" 2>/dev/null; then
                log "${GREEN}✓ Unmounted $(basename "$mount_point")${NC}"
            else
                # Try lazy unmount if regular fails
                log "${YELLOW}⚠ Regular unmount failed, trying lazy unmount...${NC}"
                umount -l "$mount_point" 2>/dev/null || log "${RED}✗ Failed to unmount $mount_point${NC}"
            fi
        fi
    done
    
    log "${GREEN}✓ Chroot unmount complete${NC}"
}

# Clean temporary files
clean_temp() {
    log "${BLUE}[3/5] Cleaning temporary files...${NC}"
    
    TEMP_DIRS=(
        "${AGENTS_MOBILE_ROOT}/tmp"
        "/tmp/agents-mobile-*"
        "${HOME}/.cache/agents-mobile"
    )
    
    for dir in "${TEMP_DIRS[@]}"; do
        if [[ -d "$dir" ]] || ls $dir >/dev/null 2>&1; then
            log "${BLUE}Cleaning $dir...${NC}"
            rm -rf $dir 2>/dev/null || true
        fi
    done
    
    log "${GREEN}✓ Temporary files cleaned${NC}"
}

# Save session state
save_state() {
    log "${BLUE}[4/5] Saving session state...${NC}"
    
    STATE_FILE="${AGENTS_MOBILE_ROOT}/state.json"
    
    # Create state snapshot
    cat > "$STATE_FILE" << EOFSTATE
{
  "last_stop": "$(date -Iseconds)",
  "environment": "$ENV",
  "bun_version": "$(bun --version 2>/dev/null || echo 'not installed')",
  "shell": "${SHELL:-unknown}",
  "uptime_before_stop": "$(uptime -p 2>/dev/null || echo 'unknown')"
}
EOFSTATE
    
    log "${GREEN}✓ State saved to $STATE_FILE${NC}"
}

# Final report
final_report() {
    log "${BLUE}[5/5] Generating shutdown report...${NC}"
    
    cat << EOFREPORT | tee -a "$LOG_FILE"

${GREEN}╔═══════════════════════════════════════════════════════╗
║                                                       ║
║          Agents-Mobile Stopped Successfully           ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝${NC}

${BLUE}📊 Shutdown Summary:${NC}
   ✓ Bun processes terminated
   ✓ Filesystems unmounted (if applicable)
   ✓ Temporary files cleaned
   ✓ Session state saved

${BLUE}📝 Log file:${NC}
   $LOG_FILE

${BLUE}🔄 To restart:${NC}
   $(which start.sh 2>/dev/null || echo './scripts/start.sh')

${YELLOW}💡 Tip:${NC}
   Your session state was saved. Next start will be faster!

EOFREPORT
}

# Error handler
error_handler() {
    log "${RED}✗ Error occurred during shutdown (line $1)${NC}"
    log "${YELLOW}Check log file: $LOG_FILE${NC}"
}

trap 'error_handler $LINENO' ERR

# Main execution
main() {
    detect_env
    kill_bun_processes
    unmount_chroot
    clean_temp
    save_state
    final_report
}

main "$@"
