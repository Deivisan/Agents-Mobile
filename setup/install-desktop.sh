#!/usr/bin/env bash
#
# install-desktop.sh - Agents-Mobile for Desktop/WSL/Mac
#
# This script adapts Agents-Mobile for desktop environments:
#   - WSL 2 (Windows Subsystem for Linux)
#   - Linux (native)
#   - macOS (via Homebrew)
#
# Key differences from mobile:
#   - No chroot needed (already running full Linux)
#   - Skip mobile-specific optimizations (thermal, battery)
#   - Use native package managers (apt, pacman, brew)
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/Deivisan/Agents-Mobile/master/setup/install-desktop.sh | bash

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Configuration
INSTALL_DIR="${HOME}/.agents-mobile"
REPO_URL="https://github.com/Deivisan/Agents-Mobile.git"
LOG_FILE="${HOME}/.agents-mobile-install.log"

# Logging
exec > >(tee -a "$LOG_FILE")
exec 2>&1

echo -e "${MAGENTA}"
cat << 'EOF'
╔══════════════════════════════════════════════════════╗
║                                                      ║
║        🖥️  AGENTS-MOBILE - DESKTOP EDITION           ║
║                                                      ║
║     Transform your desktop into an AGI workstation  ║
║                                                      ║
╚══════════════════════════════════════════════════════╝
EOF
echo -e "${NC}\n"

# Detect OS
detect_os() {
    echo -e "${BLUE}[1/7] Detecting operating system...${NC}"
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if grep -qi microsoft /proc/version 2>/dev/null; then
            OS="wsl"
            echo -e "${GREEN}✓ Windows Subsystem for Linux detected${NC}"
        else
            OS="linux"
            . /etc/os-release
            echo -e "${GREEN}✓ Linux detected: $PRETTY_NAME${NC}"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        echo -e "${GREEN}✓ macOS detected${NC}"
    else
        echo -e "${RED}✗ Unsupported OS: $OSTYPE${NC}"
        exit 1
    fi
}

# Detect package manager
detect_package_manager() {
    echo -e "${BLUE}[2/7] Detecting package manager...${NC}"
    
    if command -v apt &>/dev/null; then
        PKG_MGR="apt"
        PKG_INSTALL="sudo apt install -y"
        PKG_UPDATE="sudo apt update"
    elif command -v pacman &>/dev/null; then
        PKG_MGR="pacman"
        PKG_INSTALL="sudo pacman -S --noconfirm"
        PKG_UPDATE="sudo pacman -Sy"
    elif command -v dnf &>/dev/null; then
        PKG_MGR="dnf"
        PKG_INSTALL="sudo dnf install -y"
        PKG_UPDATE="sudo dnf check-update || true"
    elif command -v brew &>/dev/null; then
        PKG_MGR="brew"
        PKG_INSTALL="brew install"
        PKG_UPDATE="brew update"
    else
        echo -e "${RED}✗ No supported package manager found${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Using $PKG_MGR${NC}"
}

# Install system dependencies
install_deps() {
    echo -e "${BLUE}[3/7] Installing system dependencies...${NC}"
    
    $PKG_UPDATE
    
    # Core tools
    DEPS="git curl wget unzip zsh vim jq"
    
    # Add ripgrep/fzf (may have different names)
    if [[ "$PKG_MGR" == "apt" ]]; then
        DEPS="$DEPS ripgrep fzf bat"
    elif [[ "$PKG_MGR" == "pacman" ]]; then
        DEPS="$DEPS ripgrep fzf bat"
    elif [[ "$PKG_MGR" == "dnf" ]]; then
        DEPS="$DEPS ripgrep fzf bat"
    elif [[ "$PKG_MGR" == "brew" ]]; then
        DEPS="$DEPS ripgrep fzf bat"
    fi
    
    $PKG_INSTALL $DEPS
    echo -e "${GREEN}✓ System dependencies installed${NC}"
}

# Install Bun runtime
install_bun() {
    echo -e "${BLUE}[4/7] Installing Bun runtime...${NC}"
    
    if command -v bun &>/dev/null; then
        BUN_VERSION=$(bun --version)
        echo -e "${YELLOW}⚠ Bun already installed: v$BUN_VERSION${NC}"
        read -p "$(echo -e ${BLUE}Reinstall? [y/N]:${NC} )" -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return
        fi
    fi
    
    # Official Bun installer
    curl -fsSL https://bun.sh/install | bash
    
    # Add to PATH
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
    
    # Add to shell RC
    for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
        if [[ -f "$rc" ]] && ! grep -q "BUN_INSTALL" "$rc"; then
            cat >> "$rc" << 'EOFBUN'

# Bun runtime
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
EOFBUN
        fi
    done
    
    echo -e "${GREEN}✓ Bun installed: $(bun --version)${NC}"
}

# Clone Agents-Mobile repository
clone_repo() {
    echo -e "${BLUE}[5/7] Cloning Agents-Mobile repository...${NC}"
    
    if [[ -d "$INSTALL_DIR" ]]; then
        echo -e "${YELLOW}⚠ Repository already exists - pulling updates${NC}"
        git -C "$INSTALL_DIR" pull
    else
        git clone "$REPO_URL" "$INSTALL_DIR"
        echo -e "${GREEN}✓ Repository cloned${NC}"
    fi
}

# Install Oh My Zsh (optional)
install_omz() {
    echo -e "${BLUE}[6/7] Installing Oh My Zsh (optional)...${NC}"
    
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        echo -e "${YELLOW}⚠ Oh My Zsh already installed${NC}"
        return
    fi
    
    read -p "$(echo -e ${BLUE}Install Oh My Zsh? [Y/n]:${NC} )" -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        echo -e "${GREEN}✓ Oh My Zsh installed${NC}"
        
        # Enable useful plugins
        sed -i 's/plugins=(git)/plugins=(git command-not-found zsh-autosuggestions zsh-syntax-highlighting)/' "$HOME/.zshrc"
        
        # Install zsh-autosuggestions
        git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" 2>/dev/null || true
        
        # Install zsh-syntax-highlighting
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" 2>/dev/null || true
    fi
}

# Configure Agents-Mobile
configure() {
    echo -e "${BLUE}[7/7] Configuring Agents-Mobile...${NC}"
    
    # Source aliases in shell RC
    SHELL_RC="$HOME/.zshrc"
    [[ ! -f "$SHELL_RC" ]] && SHELL_RC="$HOME/.bashrc"
    
    if ! grep -q "agents-mobile/aliases" "$SHELL_RC" 2>/dev/null; then
        cat >> "$SHELL_RC" << EOFRC

# Agents-Mobile aliases
source "$INSTALL_DIR/aliases/core.zsh"

# Agents-Mobile environment
export AGENTS_MOBILE_ROOT="$INSTALL_DIR"
export AGENTS_MOBILE_PLATFORM="desktop"
EOFRC
        echo -e "${GREEN}✓ Aliases added to $SHELL_RC${NC}"
    fi
    
    # Make scripts executable
    chmod +x "$INSTALL_DIR/setup"/*.sh
    chmod +x "$INSTALL_DIR/scripts"/*.sh 2>/dev/null || true
    chmod +x "$INSTALL_DIR/tests"/*.sh
    
    echo -e "${GREEN}✓ Configuration complete${NC}"
}

# Final message
finalize() {
    cat << EOF

${GREEN}╔══════════════════════════════════════════════════════════╗
║                                                          ║
║            ✓ Installation Complete!                     ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝${NC}

${BLUE}📦 Installation directory:${NC}
   $INSTALL_DIR

${BLUE}🔧 What was installed:${NC}
   ✓ Bun runtime ($(bun --version 2>/dev/null || echo "not in current PATH"))
   ✓ Development tools (git, curl, ripgrep, fzf, bat)
   ✓ Agents-Mobile repository
   ✓ Shell aliases and configuration

${YELLOW}⚡ Next steps:${NC}

   1. Reload your shell:
      ${MAGENTA}source ~/.zshrc${NC}  # or ~/.bashrc

   2. Verify installation:
      ${MAGENTA}bun --version${NC}
      ${MAGENTA}agents-info${NC}  # (alias from Agents-Mobile)

   3. Explore available skills:
      ${MAGENTA}cd $INSTALL_DIR/skills${NC}
      ${MAGENTA}ls -la${NC}

   4. Run tests:
      ${MAGENTA}cd $INSTALL_DIR/tests${NC}
      ${MAGENTA}./test-install.sh${NC}

${BLUE}📚 Documentation:${NC}
   https://github.com/Deivisan/Agents-Mobile

${BLUE}🎯 Desktop-specific features:${NC}
   - Full access to system resources (no chroot needed)
   - All skills work natively
   - Integrated with system package manager
   - Compatible with existing development tools

${YELLOW}💡 Tip:${NC}
   Desktop mode skips mobile optimizations (thermal, battery).
   If you're using WSL, consider enabling systemd for better
   service management.

EOF

    if [[ "$OS" == "wsl" ]]; then
        cat << EOFWSL
${MAGENTA}🪟 WSL-specific tips:${NC}
   - Enable systemd: Add ${BLUE}[boot]${NC} and ${BLUE}systemd=true${NC} to /etc/wsl.conf
   - Access Windows files: ${BLUE}/mnt/c/Users/YourName${NC}
   - Best terminal: Windows Terminal (supports Unicode/emojis)

EOFWSL
    fi

    echo -e "${GREEN}Happy coding! 🚀${NC}\n"
}

# Main execution
main() {
    detect_os
    detect_package_manager
    install_deps
    install_bun
    clone_repo
    install_omz
    configure
    finalize
}

main "$@"
