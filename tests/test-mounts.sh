#!/bin/bash
# 🧪 Test mount configurations
# Validates that all mounts are working correctly in chroot environment

set -e

TEST_LOG="logs/test-mounts-$(date +%Y%m%d-%H%M%S).log"
mkdir -p logs

echo "🧪 Mount Configuration Test" | tee "$TEST_LOG"
echo "===========================" | tee -a "$TEST_LOG"
echo "" | tee -a "$TEST_LOG"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "⚠️  This test requires root access" | tee -a "$TEST_LOG"
    echo "   Run: sudo bash tests/test-mounts.sh" | tee -a "$TEST_LOG"
    exit 1
fi

# Check if chroot exists
ARCH_DIR="$HOME/arch-chroot"
if [[ ! -d "$ARCH_DIR" ]]; then
    echo "❌ Chroot directory not found: $ARCH_DIR" | tee -a "$TEST_LOG"
    echo "   Run setup/install.sh first" | tee -a "$TEST_LOG"
    exit 1
fi

PASSED=0
FAILED=0

test_mount() {
    local name="$1"
    local path="$2"
    local type="$3"
    
    echo -n "Testing $name... " | tee -a "$TEST_LOG"
    
    if mount | grep -q "$path" && mount | grep "$path" | grep -q "type $type"; then
        echo "✅ PASS" | tee -a "$TEST_LOG"
        ((PASSED++))
        return 0
    else
        echo "❌ FAIL" | tee -a "$TEST_LOG"
        ((FAILED++))
        return 1
    fi
}

test_writable() {
    local name="$1"
    local path="$2"
    
    echo -n "Testing $name writable... " | tee -a "$TEST_LOG"
    
    local testfile="$path/.agents-mobile-test-$$"
    if touch "$testfile" 2>/dev/null && rm "$testfile" 2>/dev/null; then
        echo "✅ PASS" | tee -a "$TEST_LOG"
        ((PASSED++))
        return 0
    else
        echo "❌ FAIL" | tee -a "$TEST_LOG"
        ((FAILED++))
        return 1
    fi
}

# Setup mounts (if not already mounted)
echo "Setting up mounts..." | tee -a "$TEST_LOG"
bash "$ARCH_DIR/../start-arch.sh" &
CHROOT_PID=$!
sleep 2

# Test critical mounts
test_mount "/proc" "$ARCH_DIR/proc" "proc"
test_mount "/sys" "$ARCH_DIR/sys" "sysfs"
test_mount "/dev" "$ARCH_DIR/dev" "devtmpfs"
test_mount "/dev/shm" "$ARCH_DIR/dev/shm" "tmpfs"
test_mount "/run" "$ARCH_DIR/run" "tmpfs"

# Test storage mounts
if [[ -d /sdcard ]]; then
    test_mount "/sdcard" "$ARCH_DIR/sdcard" "fuse"
fi

if [[ -d /data ]]; then
    test_mount "/data" "$ARCH_DIR/data" "ext4"
fi

# Test writable access
test_writable "/dev/shm" "$ARCH_DIR/dev/shm"
test_writable "/run" "$ARCH_DIR/run"

if [[ -d "$ARCH_DIR/sdcard" ]]; then
    test_writable "/sdcard" "$ARCH_DIR/sdcard"
fi

# Test inside chroot
echo "" | tee -a "$TEST_LOG"
echo "Testing inside chroot..." | tee -a "$TEST_LOG"

chroot "$ARCH_DIR" /bin/bash <<'CHROOT_TEST'
# Check if basic commands work
ps aux > /dev/null 2>&1 && echo "✅ ps command works"
free -h > /dev/null 2>&1 && echo "✅ free command works"
df -h > /dev/null 2>&1 && echo "✅ df command works"

# Check /dev/shm writable
touch /dev/shm/test-$$ && rm /dev/shm/test-$$ && echo "✅ /dev/shm writable in chroot"

# Check Bun works
if command -v bun &> /dev/null; then
    bun -e "console.log('Bun works')" && echo "✅ Bun executes in chroot"
fi
CHROOT_TEST

# Cleanup
kill $CHROOT_PID 2>/dev/null || true

# Summary
echo "" | tee -a "$TEST_LOG"
echo "===================================" | tee -a "$TEST_LOG"
echo "Test Summary:" | tee -a "$TEST_LOG"
echo "  ✅ Passed: $PASSED" | tee -a "$TEST_LOG"
echo "  ❌ Failed: $FAILED" | tee -a "$TEST_LOG"
echo "" | tee -a "$TEST_LOG"

if [[ $FAILED -eq 0 ]]; then
    echo "🎉 All mount tests passed!" | tee -a "$TEST_LOG"
    exit 0
else
    echo "⚠️  Some mount tests failed. Check log: $TEST_LOG" | tee -a "$TEST_LOG"
    exit 1
fi
