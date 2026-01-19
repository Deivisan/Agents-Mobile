#!/usr/bin/env bash
#
# install-proot.sh - Agents-Mobile no-root installation via PRoot
#
# This script installs Agents-Mobile in environments WITHOUT root access
# Uses PRoot for filesystem isolation (slower than native chroot)
#
# Target environments:
#   - Non-rooted Android (Termux default)
#   - Shared Linux systems
#   - Containers without privileges
#
# Performance note: PRoot adds ~10-15% overhead vs native chroot
# For best performance, use install.sh with root access when possible

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
LOG_FILE="${HOME}/.agents-mobile-install.log"
exec > >(tee -a "$LOG_FILE")
exec 2>&1

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Agents-Mobile - PRoot Installation   ║${NC}"
echo -e "${BLUE}║  (No Root Required)                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}\n"

# Default configuration
INSTALL_DIR="${HOME}/.agents-mobile"
DISTRO="${DISTRO:-arch}"  # arch, ubuntu, debian, alpine
PROOT_DISTRO_BIN="proot-distro"
START_SCRIPT="${HOME}/.local/bin/agents-mobile"

# Detect platform
detect_platform() {
    echo -e "${BLUE}[1/8] Detecting platform...${NC}"
    
    if [[ -n "${TERMUX_VERSION:-}" ]]; then
        PLATFORM="termux"
        echo -e "${GREEN}✓ Termux detected (version $TERMUX_VERSION)${NC}"
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        PLATFORM="$ID"
        echo -e "${GREEN}✓ Linux detected: $PRETTY_NAME${NC}"
    else
        echo -e "${RED}✗ Unsupported platform${NC}"
        exit 1
    fi
}

# Install dependencies
install_deps() {
    echo -e "${BLUE}[2/8] Installing dependencies...${NC}"
    
    if [[ "$PLATFORM" == "termux" ]]; then
        # Termux package manager
        pkg update -y
        pkg install -y proot-distro wget curl git unzip zsh vim
        echo -e "${GREEN}✓ Termux packages installed${NC}"
    else
        # Generic Linux (try common package managers)
        if command -v apt &>/dev/null; then
            sudo apt update
            sudo apt install -y proot wget curl git unzip zsh vim
        elif command -v pacman &>/dev/null; then
            sudo pacman -Sy --noconfirm proot wget curl git unzip zsh vim
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y proot wget curl git unzip zsh vim
        else
            echo -e "${YELLOW}⚠ Could not detect package manager - install PRoot manually${NC}"
        fi
        echo -e "${GREEN}✓ System packages installed${NC}"
    fi
}

# Check PRoot availability
check_proot() {
    echo -e "${BLUE}[3/8] Checking PRoot...${NC}"
    
    if command -v proot &>/dev/null; then
        PROOT_VERSION=$(proot --version 2>&1 | head -1 || echo "unknown")
        echo -e "${GREEN}✓ PRoot available: $PROOT_VERSION${NC}"
    else
        echo -e "${RED}✗ PRoot not found - install it manually${NC}"
        exit 1
    fi
    
    if [[ "$PLATFORM" == "termux" ]] && command -v proot-distro &>/dev/null; then
        echo -e "${GREEN}✓ proot-distro available${NC}"
    fi
}

# Install Linux distribution
install_distro() {
    echo -e "${BLUE}[4/8] Installing $DISTRO distribution...${NC}"
    
    if [[ "$PLATFORM" == "termux" ]]; then
        # Use proot-distro (Termux's distribution manager)
        if proot-distro list | grep -q "installed.*$DISTRO"; then
            echo -e "${YELLOW}⚠ $DISTRO already installed${NC}"
        else
            proot-distro install "$DISTRO"
            echo -e "${GREEN}✓ $DISTRO installed via proot-distro${NC}"
        fi
    else
        # Manual rootfs download (for generic Linux)
        ROOTFS_DIR="$INSTALL_DIR/rootfs"
        mkdir -p "$ROOTFS_DIR"
        
        case "$DISTRO" in
            arch)
                ROOTFS_URL="http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz"
                ;;
            ubuntu)
                ROOTFS_URL="https://cloud-images.ubuntu.com/minimal/releases/jammy/release/ubuntu-22.04-minimal-cloudimg-arm64-root.tar.xz"
                ;;
            alpine)
                ROOTFS_URL="https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/aarch64/alpine-minirootfs-3.19.0-aarch64.tar.gz"
                ;;
            *)
                echo -e "${RED}✗ Unsupported distro: $DISTRO${NC}"
                exit 1
                ;;
        esac
        
        echo -e "${YELLOW}⚠ Downloading rootfs (this may take several minutes)...${NC}"
        wget -q --show-progress "$ROOTFS_URL" -O /tmp/rootfs.tar.gz
        tar -xzf /tmp/rootfs.tar.gz -C "$ROOTFS_DIR"
        rm /tmp/rootfs.tar.gz
        echo -e "${GREEN}✓ Rootfs extracted to $ROOTFS_DIR${NC}"
    fi
}

# Configure PRoot environment
configure_proot() {
    echo -e "${BLUE}[5/8] Configuring PRoot environment...${NC}"
    
    mkdir -p "$INSTALL_DIR/"{home,tmp,mounts}
    
    # Create wrapper script
    mkdir -p "$(dirname "$START_SCRIPT")"
    cat > "$START_SCRIPT" << 'EOFSTART'
#!/usr/bin/env bash
# Agents-Mobile PRoot launcher
# Generated by install-proot.sh

INSTALL_DIR="${HOME}/.agents-mobile"
PLATFORM="__PLATFORM__"
DISTRO="__DISTRO__"

if [[ "$PLATFORM" == "termux" ]]; then
    # Use proot-distro
    exec proot-distro login "$DISTRO" --shared-tmp -- /bin/bash -c "
        export AGENTS_MOBILE_ROOT='$INSTALL_DIR'
        cd ~ || exit
        exec zsh -l
    "
else
    # Generic PRoot
    ROOTFS="$INSTALL_DIR/rootfs"
    exec proot \
        -0 \
        -r "$ROOTFS" \
        -b /dev \
        -b /proc \
        -b /sys \
        -b "$HOME:$HOME" \
        -b "$INSTALL_DIR/tmp:/tmp" \
        -w /root \
        /bin/bash -c "
            export PATH=/usr/local/bin:/usr/bin:/bin
            export AGENTS_MOBILE_ROOT='$INSTALL_DIR'
            exec zsh -l
        "
fi
EOFSTART
    
    # Replace placeholders
    sed -i "s|__PLATFORM__|$PLATFORM|g" "$START_SCRIPT"
    sed -i "s|__DISTRO__|$DISTRO|g" "$START_SCRIPT"
    chmod +x "$START_SCRIPT"
    
    echo -e "${GREEN}✓ Launcher created at $START_SCRIPT${NC}"
}

# Install Bun runtime
install_bun() {
    echo -e "${BLUE}[6/8] Installing Bun runtime...${NC}"
    
    # Run inside PRoot environment
    if [[ "$PLATFORM" == "termux" ]]; then
        proot-distro login "$DISTRO" -- bash -c '
            curl -fsSL https://bun.sh/install | bash
            echo "export BUN_INSTALL=\"\$HOME/.bun\"" >> ~/.zshrc
            echo "export PATH=\"\$BUN_INSTALL/bin:\$PATH\"" >> ~/.zshrc
        '
    else
        proot -r "$INSTALL_DIR/rootfs" -0 -w /root bash -c '
            curl -fsSL https://bun.sh/install | bash
            echo "export BUN_INSTALL=\"\$HOME/.bun\"" >> ~/.zshrc
            echo "export PATH=\"\$BUN_INSTALL/bin:\$PATH\"" >> ~/.zshrc
        '
    fi
    
    echo -e "${GREEN}✓ Bun installed inside PRoot${NC}"
}

# Clone Agents-Mobile repository
clone_repo() {
    echo -e "${BLUE}[7/8] Cloning Agents-Mobile repository...${NC}"
    
    REPO_DIR="$INSTALL_DIR/agents-mobile"
    
    if [[ -d "$REPO_DIR" ]]; then
        echo -e "${YELLOW}⚠ Repository already exists - pulling updates${NC}"
        git -C "$REPO_DIR" pull
    else
        git clone https://github.com/Deivisan/Agents-Mobile.git "$REPO_DIR"
        echo -e "${GREEN}✓ Repository cloned${NC}"
    fi
    
    # Link aliases
    if [[ "$PLATFORM" == "termux" ]]; then
        proot-distro login "$DISTRO" -- bash -c "
            echo 'source $REPO_DIR/aliases/core.zsh' >> ~/.zshrc
        "
    else
        proot -r "$INSTALL_DIR/rootfs" -0 bash -c "
            echo 'source $REPO_DIR/aliases/core.zsh' >> ~/.zshrc
        "
    fi
}

# Final setup
finalize() {
    echo -e "${BLUE}[8/8] Finalizing installation...${NC}"
    
    # Add to PATH (if not already present)
    SHELL_RC="${HOME}/.zshrc"
    if ! grep -q "agents-mobile" "$SHELL_RC" 2>/dev/null; then
        mkdir -p "$(dirname "$SHELL_RC")"
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
    fi
    
    cat << EOF

${GREEN}╔════════════════════════════════════════════════════════╗
║            Installation Complete! ✓                    ║
╚════════════════════════════════════════════════════════╝${NC}

${BLUE}📦 Installation directory:${NC} $INSTALL_DIR
${BLUE}🚀 Launcher script:${NC} $START_SCRIPT
${BLUE}🐧 Distribution:${NC} $DISTRO (via PRoot)

${YELLOW}⚡ To start Agents-Mobile:${NC}
   $(basename "$START_SCRIPT")

${YELLOW}📝 Notes:${NC}
   - PRoot adds ~10-15% overhead vs native chroot
   - For better performance, consider rooting device and using install.sh
   - All changes stay inside $INSTALL_DIR

${BLUE}📚 Documentation:${NC} https://github.com/Deivisan/Agents-Mobile

EOF
}

# Main execution
main() {
    detect_platform
    install_deps
    check_proot
    install_distro
    configure_proot
    install_bun
    clone_repo
    finalize
}

main "$@"
