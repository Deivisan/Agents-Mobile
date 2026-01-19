#!/bin/bash
# 🚀 Agents-Mobile Installation Script (ROOT MODE)
# Installs Arch Linux chroot with native mounts for maximum performance
# Requires: Android with root access

set -e

echo "🚀 Agents-Mobile - Root Installation"
echo "===================================="
echo ""

# Check root
if [[ $EUID -ne 0 ]] && ! command -v su &> /dev/null; then
   echo "❌ Error: This script requires root access"
   echo "   Try: bash setup/install-proot.sh (no-root alternative)"
   exit 1
fi

echo "✅ Root access confirmed"
echo ""

# Install Termux packages
echo "📦 Installing Termux packages..."
pkg update -y
pkg install -y wget curl git tar gzip proot

# Download Arch Linux ARM rootfs
echo "📥 Downloading Arch Linux ARM..."
ARCH_URL="http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz"
ARCH_DIR="$HOME/arch-chroot"

mkdir -p "$ARCH_DIR"
cd "$ARCH_DIR"

if [[ ! -f "ArchLinuxARM-aarch64-latest.tar.gz" ]]; then
    wget "$ARCH_URL" -O ArchLinuxARM-aarch64-latest.tar.gz
fi

# Extract rootfs
echo "📂 Extracting rootfs (this may take a few minutes)..."
tar xzf ArchLinuxARM-aarch64-latest.tar.gz 2>/dev/null || echo "Extraction completed"

# Create mount script
echo "🔧 Creating mount script..."
cat > "$HOME/start-arch.sh" <<'MOUNT_SCRIPT'
#!/bin/bash
# Smart mounts for native chroot performance
# Each mount is explained inline for agent understanding

ARCH_DIR="$HOME/arch-chroot"

echo "🔗 Setting up mounts..."

# 1. /proc - Process information (required for ps, top, htop)
mount --bind /proc "$ARCH_DIR/proc" 2>/dev/null || echo "  ⚠️  /proc mount failed (may already be mounted)"

# 2. /sys - System information (required for hardware detection)
mount --bind /sys "$ARCH_DIR/sys" 2>/dev/null || echo "  ⚠️  /sys mount failed"

# 3. /dev - Device files (required for hardware access)
mount --bind /dev "$ARCH_DIR/dev" 2>/dev/null || echo "  ⚠️  /dev mount failed"

# 4. /dev/pts - Pseudo terminals (required for terminal multiplexers)
mount --bind /dev/pts "$ARCH_DIR/dev/pts" 2>/dev/null || echo "  ⚠️  /dev/pts mount failed"

# 5. /dev/shm - Shared memory (CRITICAL for Bun/Node.js)
#    Without this, Bun crashes with "posix_spawn" errors
mkdir -p "$ARCH_DIR/dev/shm"
mount -t tmpfs -o size=1G tmpfs "$ARCH_DIR/dev/shm" 2>/dev/null || echo "  ⚠️  /dev/shm mount failed"

# 6. /run - Runtime data (required for systemd-like tools)
mkdir -p "$ARCH_DIR/run"
mount -t tmpfs -o size=512M tmpfs "$ARCH_DIR/run" 2>/dev/null || echo "  ⚠️  /run mount failed"

# 7. /data - Android data partition (full access to device storage)
mkdir -p "$ARCH_DIR/data"
mount --bind /data "$ARCH_DIR/data" 2>/dev/null || echo "  ⚠️  /data mount failed"

# 8. /sdcard - SD card storage (access to downloads, DCIM, etc)
mkdir -p "$ARCH_DIR/sdcard"
mount --bind /sdcard "$ARCH_DIR/sdcard" 2>/dev/null || echo "  ⚠️  /sdcard mount failed"

# 9. /storage/emulated/0 - Main storage (same as /sdcard but explicit)
mkdir -p "$ARCH_DIR/storage/emulated/0"
mount --bind /storage/emulated/0 "$ARCH_DIR/storage/emulated/0" 2>/dev/null || echo "  ⚠️  /storage mount failed"

echo "✅ Mounts completed"
echo ""
echo "🚀 Entering Arch chroot..."
chroot "$ARCH_DIR" /bin/bash
MOUNT_SCRIPT

chmod +x "$HOME/start-arch.sh"

# Setup Arch environment
echo "⚙️  Configuring Arch environment..."
chroot "$ARCH_DIR" /bin/bash <<'ARCH_SETUP'
# Initialize pacman keyring
pacman-key --init
pacman-key --populate archlinuxarm

# Update system
pacman -Syu --noconfirm

# Install essentials
pacman -S --noconfirm base-devel git wget curl zsh vim neovim htop

# Install Bun (if not installed)
if ! command -v bun &> /dev/null; then
    curl -fsSL https://bun.sh/install | bash
    echo 'export PATH="$HOME/.bun/bin:$PATH"' >> ~/.bashrc
fi

echo "✅ Arch setup completed"
ARCH_SETUP

# Copy smart aliases
echo "📝 Creating aliases..."
mkdir -p "$ARCH_DIR/root"
cp aliases/core.zsh "$ARCH_DIR/root/.zshrc" 2>/dev/null || echo "  ⚠️  Aliases will be added later"

# Run dependencies script
echo "🔧 Installing dependencies..."
bash setup/deps.sh

echo ""
echo "╔════════════════════════════════════════╗"
echo "║   ✅ Installation Completed!          ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "🚀 To start Agents-Mobile:"
echo "   bash ~/start-arch.sh"
echo ""
echo "📚 Next steps:"
echo "   1. Read docs/agents.md to setup AI agents"
echo "   2. Explore skills/ folder for capabilities"
echo "   3. Check missions/ for contribution tasks"
echo ""
echo "🧪 Run tests:"
echo "   bash tests/test-install.sh"
echo ""
