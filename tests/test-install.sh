#!/bin/bash
# 🧪 Test Agents-Mobile installation
# Validates that all core components are installed correctly

set -e

TEST_LOG="logs/test-install-$(date +%Y%m%d-%H%M%S).log"
mkdir -p logs

echo "🧪 Agents-Mobile Installation Test" | tee "$TEST_LOG"
echo "===================================" | tee -a "$TEST_LOG"
echo "" | tee -a "$TEST_LOG"

PASSED=0
FAILED=0

# Helper function
test_command() {
    local name="$1"
    local command="$2"
    
    echo -n "Testing $name... " | tee -a "$TEST_LOG"
    
    if eval "$command" >> "$TEST_LOG" 2>&1; then
        echo "✅ PASS" | tee -a "$TEST_LOG"
        ((PASSED++))
        return 0
    else
        echo "❌ FAIL" | tee -a "$TEST_LOG"
        ((FAILED++))
        return 1
    fi
}

# Test 1: Bun installed
test_command "Bun installation" "command -v bun"

# Test 2: Bun version
test_command "Bun version" "bun --version"

# Test 3: Git installed
test_command "Git installation" "command -v git"

# Test 4: Essential tools
test_command "curl installed" "command -v curl"
test_command "wget installed" "command -v wget"

# Test 5: Bun can execute simple script
test_command "Bun execution" "bun -e 'console.log(\"test\")'"

# Test 6: TypeScript transpilation
test_command "TypeScript support" "bun -e 'const x: number = 5; console.log(x)'"

# Test 7: File I/O
test_command "Bun file I/O" "bun -e 'await Bun.write(\"/tmp/test.txt\", \"test\"); const f = Bun.file(\"/tmp/test.txt\"); console.log(await f.text())'"

# Test 8: JSON handling
test_command "JSON parsing" "echo '{\"test\":true}' | bun -e 'const data = await Bun.stdin.json(); console.log(data.test)'"

# Test 9: Check for /dev/shm (important for Bun)
if [[ -d /dev/shm ]]; then
    test_command "/dev/shm exists" "test -d /dev/shm"
    test_command "/dev/shm writable" "touch /dev/shm/test && rm /dev/shm/test"
else
    echo "⚠️  WARNING: /dev/shm not found - Bun may crash!" | tee -a "$TEST_LOG"
    echo "   Run: sudo mount -t tmpfs -o size=1G tmpfs /dev/shm" | tee -a "$TEST_LOG"
fi

# Test 10: Verify skills folder exists
test_command "Skills folder" "test -d skills"

# Test 11: Verify setup scripts exist
test_command "Setup scripts" "test -f setup/detect.sh && test -f setup/install.sh"

# Test 12: Scripts are executable
test_command "Scripts executable" "test -x setup/detect.sh"

# Summary
echo "" | tee -a "$TEST_LOG"
echo "===================================" | tee -a "$TEST_LOG"
echo "Test Summary:" | tee -a "$TEST_LOG"
echo "  ✅ Passed: $PASSED" | tee -a "$TEST_LOG"
echo "  ❌ Failed: $FAILED" | tee -a "$TEST_LOG"
echo "" | tee -a "$TEST_LOG"

if [[ $FAILED -eq 0 ]]; then
    echo "🎉 All tests passed!" | tee -a "$TEST_LOG"
    echo "   Agents-Mobile is ready to use." | tee -a "$TEST_LOG"
    exit 0
else
    echo "⚠️  Some tests failed. Check log: $TEST_LOG" | tee -a "$TEST_LOG"
    exit 1
fi
