#!/bin/bash
# 📦 Dependencies Installation Script
# Installs Bun, AI agents, and essential tools
# Works on both Android chroot and desktop environments

set -e

echo "📦 Installing dependencies..."
echo ""

# Detect environment
if [[ -f /system/build.prop ]]; then
    ENV="android"
elif command -v apt &> /dev/null; then
    ENV="debian"
elif command -v pacman &> /dev/null; then
    ENV="arch"
elif command -v brew &> /dev/null; then
    ENV="macos"
else
    ENV="unknown"
fi

echo "🔍 Detected environment: $ENV"
echo ""

# Install Bun
if ! command -v bun &> /dev/null; then
    echo "🚀 Installing Bun runtime..."
    curl -fsSL https://bun.sh/install | bash
    
    # Add to PATH
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
    
    # Persist to shell config
    if [[ -f "$HOME/.zshrc" ]]; then
        echo 'export BUN_INSTALL="$HOME/.bun"' >> "$HOME/.zshrc"
        echo 'export PATH="$BUN_INSTALL/bin:$PATH"' >> "$HOME/.zshrc"
    fi
    
    if [[ -f "$HOME/.bashrc" ]]; then
        echo 'export BUN_INSTALL="$HOME/.bun"' >> "$HOME/.bashrc"
        echo 'export PATH="$BUN_INSTALL/bin:$PATH"' >> "$HOME/.bashrc"
    fi
    
    echo "✅ Bun installed: $(bun --version)"
else
    echo "✅ Bun already installed: $(bun --version)"
fi

echo ""

# Install AI agents (optional - user can install later)
echo "🤖 AI Agents (optional - install manually if needed):"
echo "   - Claude Code CLI: npm install -g @anthropic-ai/claude-code"
echo "   - Gemini CLI: bun install -g gemini-cli"
echo "   - OpenCode: Follow docs at https://opencode.dev"
echo ""

# Install essential tools based on environment
if [[ "$ENV" == "arch" ]]; then
    echo "🔧 Installing Arch packages..."
    sudo pacman -S --noconfirm --needed \
        git wget curl \
        htop neovim \
        ripgrep fd bat \
        jq yq \
        pandoc \
        zsh
    
elif [[ "$ENV" == "debian" ]]; then
    echo "🔧 Installing Debian packages..."
    sudo apt update
    sudo apt install -y \
        git wget curl \
        htop neovim \
        ripgrep fd-find bat \
        jq \
        pandoc \
        zsh
    
elif [[ "$ENV" == "macos" ]]; then
    echo "🔧 Installing macOS packages..."
    brew install \
        git wget curl \
        htop neovim \
        ripgrep fd bat \
        jq yq \
        pandoc \
        zsh
fi

# Install zsh plugins (optional but recommended)
if command -v zsh &> /dev/null && [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo "🎨 Installing Oh My Zsh (optional)..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || true
fi

# Create symlinks for tools
echo "🔗 Creating symlinks..."
mkdir -p "$HOME/.local/bin"

# bat → batcat on Debian
if command -v batcat &> /dev/null && ! command -v bat &> /dev/null; then
    ln -sf "$(which batcat)" "$HOME/.local/bin/bat"
fi

# fd → fdfind on Debian
if command -v fdfind &> /dev/null && ! command -v fd &> /dev/null; then
    ln -sf "$(which fdfind)" "$HOME/.local/bin/fd"
fi

echo ""
echo "✅ Dependencies installation completed!"
echo ""
echo "🔧 Installed tools:"
command -v bun &> /dev/null && echo "   ✅ Bun: $(bun --version)"
command -v git &> /dev/null && echo "   ✅ Git: $(git --version | head -n1)"
command -v rg &> /dev/null && echo "   ✅ Ripgrep: $(rg --version | head -n1)"
command -v bat &> /dev/null && echo "   ✅ Bat: $(bat --version)"
command -v jq &> /dev/null && echo "   ✅ jq: $(jq --version)"
command -v pandoc &> /dev/null && echo "   ✅ Pandoc: $(pandoc --version | head -n1)"

echo ""
echo "📚 Next: Install AI agents manually if needed"
echo "   See docs/agents.md for instructions"
