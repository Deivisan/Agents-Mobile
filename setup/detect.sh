#!/bin/bash
# 🔍 Auto-detect hardware and OS environment
# This script identifies the platform and recommends the correct installation method

set -e

echo "🔍 Detecting environment..."
echo ""

# Detect OS
if [[ -f /system/build.prop ]]; then
    OS="Android"
    ANDROID_VERSION=$(getprop ro.build.version.release)
elif [[ -f /proc/version ]] && grep -qi microsoft /proc/version; then
    OS="WSL"
    WSL_VERSION=$(wsl.exe --version 2>/dev/null | grep "WSL version" | awk '{print $3}')
elif [[ "$(uname)" == "Darwin" ]]; then
    OS="macOS"
    MACOS_VERSION=$(sw_vers -productVersion)
elif [[ "$(uname)" == "Linux" ]]; then
    OS="Linux"
    DISTRO=$(cat /etc/os-release | grep "^ID=" | cut -d= -f2 | tr -d '"')
else
    OS="Unknown"
fi

# Detect architecture
ARCH=$(uname -m)

# Detect root access
if [[ $EUID -eq 0 ]] || command -v su &> /dev/null; then
    HAS_ROOT="Yes"
else
    HAS_ROOT="No"
fi

# Detect CPU cores
CPU_CORES=$(nproc 2>/dev/null || echo "Unknown")

# Detect RAM
if command -v free &> /dev/null; then
    TOTAL_RAM=$(free -h | awk '/^Mem:/ {print $2}')
else
    TOTAL_RAM="Unknown"
fi

# Detect Bun
if command -v bun &> /dev/null; then
    BUN_VERSION=$(bun --version)
    HAS_BUN="Yes (v$BUN_VERSION)"
else
    HAS_BUN="No"
fi

# Print results
echo "╔════════════════════════════════════════╗"
echo "║     Environment Detection Report      ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "🖥️  Operating System: $OS"
[[ "$OS" == "Android" ]] && echo "   └─ Android Version: $ANDROID_VERSION"
[[ "$OS" == "WSL" ]] && echo "   └─ WSL Version: $WSL_VERSION"
[[ "$OS" == "macOS" ]] && echo "   └─ macOS Version: $MACOS_VERSION"
[[ "$OS" == "Linux" ]] && echo "   └─ Distribution: $DISTRO"
echo ""
echo "🏗️  Architecture: $ARCH"
echo "🔐 Root Access: $HAS_ROOT"
echo "⚙️  CPU Cores: $CPU_CORES"
echo "💾 Total RAM: $TOTAL_RAM"
echo "🚀 Bun Installed: $HAS_BUN"
echo ""

# Recommend installation method
echo "📋 Recommended installation:"
echo ""

if [[ "$OS" == "Android" ]]; then
    if [[ "$HAS_ROOT" == "Yes" ]]; then
        echo "✅ Use: bash setup/install.sh (ROOT MODE - Best performance)"
        echo "   Alternative: bash setup/install-proot.sh (if you prefer no-root)"
    else
        echo "✅ Use: bash setup/install-proot.sh (NO-ROOT MODE)"
        echo "   Note: For best performance, consider rooting your device"
    fi
elif [[ "$OS" == "WSL" ]] || [[ "$OS" == "Linux" ]] || [[ "$OS" == "macOS" ]]; then
    echo "✅ Use: bash setup/install-desktop.sh (DESKTOP MODE)"
else
    echo "⚠️  Unknown OS - manual installation may be required"
    echo "   Please check docs/manual-install.md"
fi

echo ""
echo "🔧 Next steps:"
echo "   1. Run the recommended installation script"
echo "   2. Check docs/agents.md for AI agent setup"
echo "   3. Explore skills/ folder for agent capabilities"
echo ""

# Save detection results to log
mkdir -p logs
cat > logs/detection-report.json <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "os": "$OS",
  "arch": "$ARCH",
  "root": "$HAS_ROOT",
  "cpu_cores": "$CPU_CORES",
  "total_ram": "$TOTAL_RAM",
  "bun_installed": "$HAS_BUN"
}
EOF

echo "📝 Detection report saved to: logs/detection-report.json"
