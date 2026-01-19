# 🖥️ Mission 03: Desktop Testing

**Status**: 🟡 Pending  
**Difficulty**: ⭐⭐ Intermediate  
**Estimated Time**: 45-60 minutes  
**Platforms**: WSL, Linux, macOS

## 🎯 Objective

Validate that Agents-Mobile works correctly on desktop environments (WSL, native Linux, and macOS) using the `install-desktop.sh` script.

## 📋 Prerequisites

- [ ] Desktop/laptop with one of:
  - Windows 11 with WSL 2
  - Linux (Ubuntu, Arch, Fedora, etc.)
  - macOS (Intel or Apple Silicon)
- [ ] Terminal access
- [ ] Internet connection
- [ ] Git installed

## 🔧 Tasks

### Part 1: Fresh Installation

#### Task 1.1: Download and Run Installer
```bash
# Download installer
curl -fsSL https://raw.githubusercontent.com/Deivisan/Agents-Mobile/master/setup/install-desktop.sh -o /tmp/install-desktop.sh

# Review script (ALWAYS review before running)
less /tmp/install-desktop.sh

# Run installer
bash /tmp/install-desktop.sh
```

**Expected Results**:
- ✅ Script detects OS correctly
- ✅ Package manager identified
- ✅ Dependencies installed (git, curl, zsh, ripgrep, fzf, bat)
- ✅ Bun installed successfully
- ✅ Repository cloned to `~/.agents-mobile`
- ✅ Aliases added to shell RC

**Log Output**: Save to `mission-03-install.log`

---

#### Task 1.2: Verify Installation
```bash
# Reload shell
source ~/.zshrc  # or ~/.bashrc

# Check Bun
bun --version

# Check aliases
type agents-info
type brun
type projects

# Verify repo
ls -la ~/.agents-mobile
```

**Checklist**:
- [ ] Bun command available
- [ ] Version is latest (1.3.5+)
- [ ] Aliases work (try `agents-info`)
- [ ] Repository contains all folders (setup, skills, missions, etc.)

---

### Part 2: Run Tests

#### Task 2.1: Installation Test
```bash
cd ~/.agents-mobile/tests
./test-install.sh
```

**Expected Output**:
```
✓ Bun runtime detected
✓ Git available
✓ Required directories exist
✓ Scripts are executable
✓ Aliases loaded
```

**Screenshot**: `mission-03-test-install.png`

---

#### Task 2.2: Benchmarks
```bash
cd ~/.agents-mobile/scripts
./bench.sh
```

**Expected Behavior**:
- Runs Bun benchmark
- Tests disk I/O (read/write speed)
- Tests CPU (single and multi-thread)
- Tests memory bandwidth
- Generates JSON results

**Save Results**: `~/.agents-mobile/benchmarks/results-YYYYMMDD-HHMMSS.json`

**Report**:
- Overall score: `______`
- Bun score: `______`
- CPU cores used: `______`
- Disk write speed: `______ MB/s`
- Disk read speed: `______ MB/s`

---

### Part 3: Skill Testing

#### Task 3.1: Test OpenCode Skill
```bash
# Install OpenCode
bun install -g opencode

# Verify
opencode --version

# Test basic query
opencode chat "What is Bun runtime?"
```

**Expected**:
- ✅ OpenCode installs without errors
- ✅ Command responds with AI answer
- ✅ No API key errors (if configured)

**Notes**: If API key needed, document where to get it.

---

#### Task 3.2: Test Gemini CLI Skill
```bash
# Get API key from: https://ai.google.dev/aistudio
export GEMINI_API_KEY="AIza..."

# Test query
~/.local/bin/gemini "Hello, Gemini!"
```

**Expected**:
- ✅ API key accepted
- ✅ Response received
- ✅ No rate limit errors

---

#### Task 3.3: Test Bun Optimizer Skill
```bash
# Create test project
mkdir ~/test-bun-app
cd ~/test-bun-app
bun init -y

# Add dependencies
bun add express

# Run benchmark before optimization
bun build ./index.ts --outdir ./dist

# Apply optimizations from skill
# (Read skills/bun-optimizer.md and apply suggestions)

# Benchmark after
# Compare bundle sizes and performance
```

**Metrics**:
- Bundle size before: `______ KB`
- Bundle size after: `______ KB`
- Improvement: `______ %`

---

### Part 4: Environment-Specific Tests

#### WSL-Specific (if on Windows)
```bash
# Check WSL version
wsl --version

# Test Windows interop
explorer.exe .

# Test file system performance
df -h
```

**Checklist**:
- [ ] WSL 2 confirmed
- [ ] Can access Windows files (`/mnt/c/...`)
- [ ] File system is ext4 (not NTFS for projects)

---

#### macOS-Specific (if on Mac)
```bash
# Check Homebrew
brew --version

# Test Bun on Apple Silicon / Intel
uname -m  # arm64 or x86_64

# Check Rosetta (if Intel on M1/M2/M3)
pgrep -q oahd && echo "Rosetta active" || echo "Native ARM"
```

**Checklist**:
- [ ] Homebrew installed
- [ ] Architecture detected correctly
- [ ] Bun runs natively (not via Rosetta)

---

### Part 5: Stress Testing

#### Task 5.1: Concurrent Bun Processes
```bash
# Start 3 Bun servers on different ports
bun run --port 3000 &
bun run --port 3001 &
bun run --port 3002 &

# Monitor resource usage
htop  # or top

# Kill processes
pkill -f bun
```

**Observations**:
- CPU usage: `______ %`
- Memory usage: `______ MB`
- Stability: ✅ / ❌

---

#### Task 5.2: Large File Processing
```bash
# Generate 100MB test file
dd if=/dev/urandom of=/tmp/test.bin bs=1M count=100

# Process with Bun
bun run -e 'const fs = require("fs"); const data = fs.readFileSync("/tmp/test.bin"); console.log(data.length)'

# Benchmark
time bun run -e '...'
```

**Results**:
- Read time: `______ seconds`
- Memory peak: `______ MB`

---

### Part 6: Documentation

#### Task 6.1: Create Environment Report
Create file: `mission-03-report.md`

**Template**:
```markdown
# Desktop Testing Report - Mission 03

## Environment
- OS: [Linux/WSL/macOS]
- Distribution: [Ubuntu 22.04 / Arch / macOS 14]
- Shell: [zsh/bash]
- Kernel: [5.15.0 / Darwin 23.0]

## Installation
- Installer ran successfully: ✅ / ❌
- Time taken: ____ minutes
- Errors encountered: [None / List issues]

## Benchmarks
- Overall score: _____
- Bun score: _____
- CPU score: _____
- Disk I/O: _____ MB/s (read), _____ MB/s (write)

## Skills Tested
- OpenCode: ✅ / ❌ / ⚠️ (Notes: ...)
- Gemini CLI: ✅ / ❌ / ⚠️ (Notes: ...)
- Bun Optimizer: ✅ / ❌ / ⚠️ (Notes: ...)

## Issues Found
1. [Issue description]
2. [Issue description]

## Recommendations
- [Suggestion for improvement]
- [Suggestion for improvement]

## Screenshots
- Installation: [Link or attached]
- Benchmarks: [Link or attached]
```

---

#### Task 6.2: Update Hardware Matrix
Edit `docs/matrix.md` and add your device:

```markdown
| Your Device Name | [CPU] | [RAM] | [OS] | ✅/❌ | [Score] | [Your Name] |
```

---

## 📊 Success Criteria

Mission is **complete** when:

- ✅ All installation steps succeed without manual intervention
- ✅ All tests pass (`test-install.sh` exits 0)
- ✅ Benchmarks run and produce valid JSON
- ✅ At least 2 skills tested successfully
- ✅ Report created and submitted (PR or issue)
- ✅ Hardware matrix updated

## 🎁 Bonus Challenges

### Bonus 1: Performance Comparison
Compare Agents-Mobile performance vs vanilla Bun:

```bash
# Vanilla Bun benchmark
bun run bench-vanilla.ts

# Agents-Mobile optimized
bun run bench-optimized.ts

# Calculate speedup
```

### Bonus 2: Multi-Platform Test
If you have access to multiple platforms, test on all:
- ✅ WSL
- ✅ Native Linux
- ✅ macOS Intel
- ✅ macOS Apple Silicon

### Bonus 3: Dockerized Test
Create Docker container and test inside:

```bash
# Create Dockerfile
cat > Dockerfile << 'EOF'
FROM ubuntu:22.04
RUN apt update && apt install -y curl
RUN curl -fsSL https://raw.githubusercontent.com/Deivisan/Agents-Mobile/master/setup/install-desktop.sh | bash
EOF

# Build and test
docker build -t agents-mobile-test .
docker run -it agents-mobile-test
```

## 🐛 Common Issues

### Issue: Package Manager Not Detected
**Solution**: Manually install with your package manager:
```bash
# Debian/Ubuntu
sudo apt install git curl zsh vim ripgrep fzf bat

# Arch
sudo pacman -S git curl zsh vim ripgrep fzf bat

# macOS
brew install git curl zsh vim ripgrep fzf bat
```

### Issue: Bun Install Fails
**Solution**: Check architecture and retry:
```bash
uname -m  # Should be x86_64 or aarch64
curl -fsSL https://bun.sh/install | bash -s -- --verbose
```

### Issue: Permission Denied
**Solution**: Don't run as root (except package manager commands):
```bash
# Bad
sudo bash install-desktop.sh

# Good
bash install-desktop.sh  # Only uses sudo for packages
```

## 📤 Submission

When mission is complete:

1. **Create report**: `mission-03-report.md`
2. **Attach files**:
   - Installation log
   - Benchmark JSON
   - Screenshots
3. **Submit via**:
   - GitHub Issue: https://github.com/Deivisan/Agents-Mobile/issues
   - Pull Request: Add report to `missions/completed/`

## 🏆 Recognition

Successful testers will be:
- Listed in `README.md` contributors
- Added to hardware compatibility matrix
- Credited in release notes

---

**Mission Created**: 2026-01-18  
**Last Updated**: 2026-01-18  
**Author**: Agents-Mobile Team  
**Maintainer**: Deivison Santana (@deivisan)
