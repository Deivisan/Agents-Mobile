# 🎯 Mission 01: Create Sandbox Testing Environment

**Status**: 🟡 In Progress  
**Assigned To**: @deivisan (primary), open for agents  
**Difficulty**: Beginner  
**Estimated Time**: 1-2 hours  

---

## 🎯 Mission Objective

Create an **isolated sandbox environment** where all Agents-Mobile scripts can be tested safely **without affecting the main system**.

This allows:
- ✅ Testing scripts before deploying to real devices
- ✅ Validating installation procedures
- ✅ Catching bugs early
- ✅ Safe experimentation by contributors

---

## 📋 Requirements

### Environment Options

Choose **one** of these sandbox environments:

#### Option A: Docker Container (Recommended)
```bash
# Create Ubuntu ARM container
docker run -it --name agents-mobile-sandbox \
  -v $(pwd):/workspace \
  ubuntu:22.04 /bin/bash
```

#### Option B: VirtualBox VM
- Install Ubuntu Server 22.04 ARM64
- Mount Agents-Mobile repo as shared folder

#### Option C: Android Emulator (AVD)
- Android Studio AVD with root access
- Install Termux in emulator

#### Option D: WSL2 (Windows)
```bash
# Install Arch Linux in WSL2
wsl --install -d ArchLinux
```

---

## ✅ Tasks Checklist

### Phase 1: Setup Sandbox

- [ ] Choose sandbox environment (Docker/VM/AVD/WSL)
- [ ] Install base system (Ubuntu/Arch/Android)
- [ ] Mount Agents-Mobile repository
- [ ] Install basic tools (git, curl, bash)
- [ ] Document setup steps in `docs/sandbox-setup.md`

### Phase 2: Test Installation Scripts

- [ ] Run `setup/detect.sh` - verify detection works
- [ ] Run `setup/deps.sh` - verify dependencies install
- [ ] Test Bun installation - `bun --version`
- [ ] Verify mount scripts (if Android sandbox)
- [ ] Log all outputs to `logs/sandbox-test-install.log`

### Phase 3: Test Skills

- [ ] Test `skills/mcp-builder.md` - create sample MCP server
- [ ] Test `skills/mobile-debug.md` - run diagnostic commands
- [ ] Verify all code samples execute without errors
- [ ] Document any issues found

### Phase 4: Validation

- [ ] Compare sandbox results with real device (if available)
- [ ] Create `tests/test-sandbox.sh` automation script
- [ ] Update README with sandbox instructions
- [ ] Mark mission as ✅ Complete

---

## 📝 Deliverables

1. **Documentation**: `docs/sandbox-setup.md` with step-by-step guide
2. **Test Log**: `logs/sandbox-test-install.log` with full output
3. **Automation**: `tests/test-sandbox.sh` script for future runs
4. **Issue Report**: Any bugs found documented in GitHub Issues

---

## 🧪 Testing Commands

```bash
# 1. Clone repo in sandbox
git clone https://github.com/Deivisan/Agents-Mobile.git
cd Agents-Mobile

# 2. Test detection
bash setup/detect.sh

# Expected output: Environment detection report with OS/arch/RAM

# 3. Test dependencies
bash setup/deps.sh

# Expected: Bun installed, all tools present

# 4. Verify Bun
bun --version

# Expected: v1.x.x

# 5. Test MCP builder skill
cd skills
mkdir test-mcp && cd test-mcp
bun init -y
# Follow mcp-builder.md instructions

# 6. Log results
echo "Sandbox test completed at $(date)" > ../../logs/sandbox-test.log
```

---

## 🐛 Known Issues to Watch For

- **Docker ARM**: Some x86 packages may not work on ARM containers
- **Termux Emulator**: Keyboard input can be tricky in AVD
- **WSL2**: Path differences between Windows/Linux (`C:\` vs `/mnt/c/`)
- **Permissions**: Root access required for some mount operations

---

## 🤝 Collaboration

This mission can be picked up by:
- 🤖 **AI Agents**: Claude, GPT, Gemini can automate testing
- 👨‍💻 **Human Contributors**: Document edge cases, improve scripts
- 📱 **Mobile Testers**: Test on real Android devices

**How to contribute**:
1. Fork repo
2. Create branch: `mission-01-sandbox`
3. Complete tasks, update this file with ✅
4. Submit PR with logs and docs

---

## 📚 Resources

- [Docker ARM Images](https://hub.docker.com/u/arm64v8/)
- [Android Emulator Setup](https://developer.android.com/studio/run/managing-avds)
- [WSL2 Arch Install](https://github.com/yuk7/ArchWSL)
- [Termux Wiki](https://wiki.termux.com)

---

## 🎓 Learning Outcomes

After completing this mission, you will know:
- ✅ How to create isolated test environments
- ✅ How to validate shell scripts systematically
- ✅ How to automate testing workflows
- ✅ How to document technical procedures

---

**Mission Created**: 2026-01-18  
**Last Updated**: 2026-01-18  
**Next Mission**: [Mission 02: Android Device Testing](mission-02-android-test.md)
