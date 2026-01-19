#!/usr/bin/env bash
#
# start.sh - Agents-Mobile unified launcher
#
# Detects environment (native chroot, proot, desktop) and starts appropriately
# This is the primary entry point for Agents-Mobile

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Banner
show_banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
    ╔═══════════════════════════════════════════════════════╗
    ║                                                       ║
    ║              🤖  AGENTS-MOBILE  🤖                    ║
    ║                                                       ║
    ║        Transform Devices into AGI Workstations       ║
    ║                                                       ║
    ╚═══════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}\n"
}

# Detect environment type
detect_environment() {
    if [[ -n "${TERMUX_VERSION:-}" ]]; then
        # Running in Termux
        if [[ -f "/data/local/mnt/arch/etc/os-release" ]] || [[ -d "/data/local/mnt/arch" ]]; then
            ENV_TYPE="termux-chroot"
            CHROOT_DIR="/data/local/mnt/arch"
        elif command -v proot-distro &>/dev/null; then
            ENV_TYPE="termux-proot"
        else
            ENV_TYPE="termux-native"
        fi
    elif [[ -f "/.dockerenv" ]]; then
        ENV_TYPE="docker"
    elif grep -qi microsoft /proc/version 2>/dev/null; then
        ENV_TYPE="wsl"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        ENV_TYPE="macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        ENV_TYPE="linux"
    else
        ENV_TYPE="unknown"
    fi
    
    echo -e "${BLUE}🔍 Environment detected:${NC} $ENV_TYPE"
}

# Check if running as root (for chroot)
check_root() {
    if [[ "$ENV_TYPE" == "termux-chroot" ]] && [[ $EUID -ne 0 ]]; then
        echo -e "${YELLOW}⚠ Native chroot requires root access${NC}"
        echo -e "${BLUE}Attempting to elevate with su...${NC}"
        exec su -c "$0 $*"
    fi
}

# Start native chroot (Termux with root)
start_chroot() {
    echo -e "${GREEN}🚀 Starting native chroot environment...${NC}"
    
    if [[ ! -d "$CHROOT_DIR" ]]; then
        echo -e "${RED}✗ Chroot directory not found: $CHROOT_DIR${NC}"
        echo -e "${YELLOW}Run setup/install.sh first${NC}"
        exit 1
    fi
    
    # Mount necessary filesystems (if not already mounted)
    mount_chroot() {
        for mount_point in proc sys dev dev/pts; do
            if ! mountpoint -q "$CHROOT_DIR/$mount_point" 2>/dev/null; then
                case "$mount_point" in
                    proc) mount -t proc proc "$CHROOT_DIR/proc" ;;
                    sys) mount -t sysfs sysfs "$CHROOT_DIR/sys" ;;
                    dev) mount -o bind /dev "$CHROOT_DIR/dev" ;;
                    dev/pts) mount -o bind /dev/pts "$CHROOT_DIR/dev/pts" ;;
                esac
                echo -e "${GREEN}✓ Mounted /$mount_point${NC}"
            fi
        done
        
        # Special mounts
        if [[ ! -d "$CHROOT_DIR/dev/shm" ]]; then
            mkdir -p "$CHROOT_DIR/dev/shm"
            mount -t tmpfs -o size=2G tmpfs "$CHROOT_DIR/dev/shm"
            echo -e "${GREEN}✓ Mounted /dev/shm (2GB tmpfs)${NC}"
        fi
        
        # Bind Termux storage
        if [[ -d "/data/data/com.termux/files/home/storage" ]]; then
            mkdir -p "$CHROOT_DIR/mnt/termux"
            mount -o bind /data/data/com.termux/files/home/storage "$CHROOT_DIR/mnt/termux"
            echo -e "${GREEN}✓ Mounted Termux storage${NC}"
        fi
    }
    
    mount_chroot
    
    # Enter chroot
    echo -e "${CYAN}Entering chroot environment...${NC}"
    chroot "$CHROOT_DIR" /bin/bash -c "
        export HOME=/root
        export PATH=/usr/local/bin:/usr/bin:/bin:/sbin
        export TERM=xterm-256color
        export AGENTS_MOBILE_ROOT=/root/.agents-mobile
        cd ~
        
        # Source Bun
        [[ -f ~/.bun/_bun ]] && source ~/.bun/_bun
        
        # Source aliases
        [[ -f ~/.agents-mobile/aliases/core.zsh ]] && source ~/.agents-mobile/aliases/core.zsh
        
        # Start shell
        exec zsh -l
    "
}

# Start PRoot environment (Termux without root)
start_proot() {
    echo -e "${GREEN}🚀 Starting PRoot environment...${NC}"
    
    DISTRO="${AGENTS_MOBILE_DISTRO:-arch}"
    
    if ! command -v proot-distro &>/dev/null; then
        echo -e "${RED}✗ proot-distro not found${NC}"
        echo -e "${YELLOW}Install with: pkg install proot-distro${NC}"
        exit 1
    fi
    
    # Check if distro is installed
    if ! proot-distro list | grep -q "installed.*$DISTRO"; then
        echo -e "${YELLOW}⚠ $DISTRO not installed${NC}"
        echo -e "${BLUE}Run: proot-distro install $DISTRO${NC}"
        exit 1
    fi
    
    # Login to proot-distro
    echo -e "${CYAN}Entering PRoot ($DISTRO)...${NC}"
    exec proot-distro login "$DISTRO" --shared-tmp -- /bin/bash -c "
        export AGENTS_MOBILE_ROOT=~/.agents-mobile
        export AGENTS_MOBILE_MODE=proot
        cd ~
        
        # Source environment
        [[ -f ~/.bun/_bun ]] && source ~/.bun/_bun
        [[ -f ~/.agents-mobile/aliases/core.zsh ]] && source ~/.agents-mobile/aliases/core.zsh
        
        exec zsh -l
    "
}

# Start desktop/native environment
start_desktop() {
    echo -e "${GREEN}🚀 Starting desktop environment...${NC}"
    
    export AGENTS_MOBILE_ROOT="${HOME}/.agents-mobile"
    export AGENTS_MOBILE_MODE="desktop"
    
    if [[ ! -d "$AGENTS_MOBILE_ROOT" ]]; then
        echo -e "${RED}✗ Agents-Mobile not installed${NC}"
        echo -e "${YELLOW}Run: curl -fsSL https://raw.githubusercontent.com/Deivisan/Agents-Mobile/master/setup/install-desktop.sh | bash${NC}"
        exit 1
    fi
    
    # Source environment
    [[ -f "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"
    [[ -f "$AGENTS_MOBILE_ROOT/aliases/core.zsh" ]] && source "$AGENTS_MOBILE_ROOT/aliases/core.zsh"
    
    echo -e "${CYAN}Environment ready!${NC}"
    echo -e "${BLUE}Type 'agents-info' for system information${NC}\n"
    
    # Start shell or execute command
    if [[ $# -gt 0 ]]; then
        exec "$@"
    else
        exec "${SHELL:-/bin/bash}"
    fi
}

# Start Termux native (no chroot/proot)
start_termux_native() {
    echo -e "${GREEN}🚀 Starting Termux native mode...${NC}"
    echo -e "${YELLOW}⚠ Running without chroot - limited functionality${NC}"
    
    export AGENTS_MOBILE_ROOT="${HOME}/.agents-mobile"
    export AGENTS_MOBILE_MODE="termux-native"
    
    # Source environment if exists
    [[ -f "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"
    [[ -f "$AGENTS_MOBILE_ROOT/aliases/core.zsh" ]] && source "$AGENTS_MOBILE_ROOT/aliases/core.zsh"
    
    echo -e "${BLUE}Consider using chroot or proot for full features${NC}\n"
    
    exec "${SHELL:-/bin/bash}"
}

# Show environment info
show_info() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     Environment Information           ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo -e "${CYAN}Type:${NC} $ENV_TYPE"
    echo -e "${CYAN}Shell:${NC} ${SHELL:-unknown}"
    
    if command -v bun &>/dev/null; then
        echo -e "${CYAN}Bun:${NC} $(bun --version)"
    else
        echo -e "${CYAN}Bun:${NC} ${RED}not installed${NC}"
    fi
    
    if [[ -n "${AGENTS_MOBILE_ROOT:-}" ]]; then
        echo -e "${CYAN}Root:${NC} $AGENTS_MOBILE_ROOT"
    fi
    
    echo ""
}

# Main execution
main() {
    show_banner
    detect_environment
    
    # Handle flags
    case "${1:-}" in
        --info|-i)
            show_info
            exit 0
            ;;
        --help|-h)
            cat << EOFHELP
Agents-Mobile Launcher

Usage:
  start.sh [options] [command]

Options:
  --info, -i     Show environment information
  --help, -h     Show this help message

Environment types:
  termux-chroot  - Native chroot (requires root)
  termux-proot   - PRoot (no root needed)
  termux-native  - Termux without isolation
  wsl            - Windows Subsystem for Linux
  linux          - Native Linux
  macos          - macOS
  docker         - Docker container

Examples:
  start.sh              # Start interactive shell
  start.sh bun dev      # Run command in environment
  start.sh --info       # Show system info

EOFHELP
            exit 0
            ;;
    esac
    
    # Route to appropriate starter
    case "$ENV_TYPE" in
        termux-chroot)
            check_root
            start_chroot "$@"
            ;;
        termux-proot)
            start_proot "$@"
            ;;
        termux-native)
            start_termux_native "$@"
            ;;
        wsl|linux|macos|docker)
            start_desktop "$@"
            ;;
        *)
            echo -e "${RED}✗ Unsupported environment: $ENV_TYPE${NC}"
            exit 1
            ;;
    esac
}

main "$@"
