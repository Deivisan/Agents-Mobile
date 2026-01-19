# 🎯 Mission 02: Real Android Device Testing

**Status**: ⚪ Pending  
**Assigned To**: Open (requires Poco X5 5G or similar device)  
**Difficulty**: Intermediate  
**Estimated Time**: 2-4 hours  

---

## 🎯 Mission Objective

Test **all Agents-Mobile scripts and features** on a **real Android device** to validate:
- ✅ Installation procedures work end-to-end
- ✅ Performance matches claimed benchmarks
- ✅ Mounts are stable and persistent
- ✅ AI agents run correctly in mobile environment
- ✅ Battery/thermal optimizations are effective

**Target Device**: Poco X5 5G (Snapdragon 695, 8GB RAM) - or equivalent

---

## 📋 Requirements

### Hardware
- ✅ Android device with **root access** (Magisk recommended)
- ✅ **Termux** installed from F-Droid (NOT Google Play)
- ✅ USB cable for ADB debugging
- ✅ PC with ADB tools installed

### Software
- ✅ Android 11+ (tested on Android 13+)
- ✅ Kernel with ZRAM support (optional but recommended)
- ✅ Custom ROM with performance profile (optional)

---

## ✅ Tasks Checklist

### Phase 1: Pre-Flight Setup

- [ ] Install Termux from F-Droid
- [ ] Grant Termux storage permission: `termux-setup-storage`
- [ ] Install Termux API: `pkg install termux-api`
- [ ] Verify root access: `su` works
- [ ] Enable developer options + USB debugging
- [ ] Connect to PC via ADB: `adb devices`

### Phase 2: Clone & Detect

- [ ] Clone repo to device:
  ```bash
  cd /sdcard
  git clone https://github.com/Deivisan/Agents-Mobile.git
  cd Agents-Mobile
  ```
- [ ] Run detection: `bash setup/detect.sh`
- [ ] Verify output shows Android + ARM + Root
- [ ] Save detection report: Copy `logs/detection-report.json` to PC

### Phase 3: Installation (Root Mode)

- [ ] Run: `bash setup/install.sh`
- [ ] Monitor installation (should take 10-20 minutes)
- [ ] Check for errors in output
- [ ] Verify Arch chroot created: `ls ~/arch-chroot`
- [ ] Test entry: `bash ~/start-arch.sh`
- [ ] Inside chroot, verify: `pacman -Q | wc -l` (should show packages)
- [ ] Exit chroot: `exit`

### Phase 4: Benchmarking

- [ ] Run baseline tests BEFORE entering chroot:
  ```bash
  # CPU benchmark
  sysbench cpu --threads=8 run
  
  # I/O benchmark
  dd if=/dev/zero of=/sdcard/test.img bs=1M count=1024
  ```
- [ ] Enter chroot: `bash ~/start-arch.sh`
- [ ] Run same benchmarks INSIDE chroot
- [ ] Compare results - should see ~30% improvement
- [ ] Test Bun: `bun run -e "console.log('Hello from Bun')"` (https://bun.sh)
- [ ] Save benchmark results to `logs/android-benchmark.log`

### Phase 5: Skills Testing

- [ ] Test MCP Builder:
  ```bash
  cd /sdcard/Agents-Mobile/skills
  mkdir test-mcp && cd test-mcp
  # Follow mcp-builder.md instructions
  bun run index.ts
  ```
- [ ] Test Mobile Debug:
  ```bash
  # Check temperature
  cat /sys/class/thermal/thermal_zone0/temp
  
  # Check battery
  termux-battery-status
  
  # Run watchdog
  bash scripts/mobile-watchdog.sh &
  ```
- [ ] Test all code samples in skills/ folder
- [ ] Document any crashes/errors

### Phase 6: AI Agent Integration

- [ ] Install AI agent (choose one):
  - Claude Code: `npm install -g @anthropic-ai/claude-code`
  - Gemini CLI: `bun install -g gemini-cli`
  - OpenCode: Follow https://opencode.dev setup
- [ ] Load skill: Point agent to `skills/` folder
- [ ] Test agent can read and execute skills
- [ ] Example: Ask agent to "create an MCP server using mcp-builder.md"
- [ ] Verify agent completes task successfully

### Phase 7: Stress Testing

- [ ] Run heavy workload for 30 minutes:
  ```bash
  # Infinite loop Bun script
  while true; do
    bun run -e "Array(1000000).fill(0).map((_, i) => i * 2)"
    sleep 1
  done
  ```
- [ ] Monitor with watchdog script
- [ ] Check thermal throttling behavior
- [ ] Verify no OOM kills
- [ ] Stop test, check device stability

### Phase 8: Persistence Testing

- [ ] Reboot device
- [ ] Re-enter chroot: `bash ~/start-arch.sh`
- [ ] Verify all mounts still work
- [ ] Check Bun still functional
- [ ] Test agent remembers context (if using MCP)
- [ ] Document any mount failures

---

## 📝 Deliverables

1. **Full Test Log**: `logs/android-test-full.log` (entire terminal output)
2. **Benchmark Results**: `logs/android-benchmark.json` with before/after metrics
3. **Screenshots**: Photos of device showing:
   - Termux running chroot
   - Bun version output
   - AI agent executing skill
   - Thermal/battery stats during stress test
4. **Issue Report**: GitHub issues for any bugs found
5. **Device Specs**: `logs/device-specs.json` with kernel version, ROM, etc.

---

## 📊 Success Criteria

| Metric | Target | Pass/Fail |
|--------|--------|-----------|
| Installation completes | No errors | ⬜ |
| Chroot entry works | Boots to shell | ⬜ |
| Bun runs successfully | v1.x.x output | ⬜ |
| CPU benchmark improvement | +20% vs vanilla | ⬜ |
| I/O benchmark improvement | +15% vs vanilla | ⬜ |
| No thermal shutdown | < 80°C under load | ⬜ |
| No OOM kills | Runs 30min stress test | ⬜ |
| Mounts persist | After reboot | ⬜ |
| AI agent executes skill | Creates MCP server | ⬜ |

---

## 🐛 Known Issues to Test

- [ ] `/dev/shm` mount - Bun crashes without this?
- [ ] ZRAM config - Does it activate correctly?
- [ ] Thermal throttling - Does watchdog pause tasks?
- [ ] Battery drain - How long can device run agents?
- [ ] Mount persistence - Do mounts survive `su` session end?

---

## 🔧 Troubleshooting

| Problem | Solution |
|---------|----------|
| "Permission denied" on mount | Run as root: `su` first |
| Bun crashes with "posix_spawn" | Check /dev/shm is mounted (tmpfs) |
| Slow I/O in chroot | Verify using native chroot, not proot |
| Thermal shutdown during test | Lower CPU usage, increase pauses |
| Termux crashes on reboot | Reinstall Termux-API, grant permissions |

---

## 📸 Evidence Required

Take screenshots/photos of:
1. `setup/detect.sh` output showing device info
2. `bash ~/start-arch.sh` showing successful chroot entry
3. `bun --version` output inside chroot
4. `termux-battery-status` during stress test
5. `cat /sys/class/thermal/thermal_zone0/temp` showing temperature
6. AI agent reading `mcp-builder.md` and creating server

Upload to `assets/android-test/` folder.

---

## 🤝 Collaboration

**Ideal Tester Profile**:
- Has rooted Android device (Poco X5 5G or similar)
- Comfortable with Termux and command line
- Can dedicate 2-4 hours for thorough testing
- Can document findings clearly

**How to Claim This Mission**:
1. Comment on GitHub: "I'll test on [Device Model]"
2. Fork repo, create branch: `mission-02-android-test`
3. Complete testing, document results
4. Submit PR with logs + screenshots

---

## 📚 Resources

- [Termux Wiki - Chroot](https://wiki.termux.com/wiki/PRoot)
- [Magisk Root Guide](https://topjohnwu.github.io/Magisk/)
- [Arch Linux ARM](https://archlinuxarm.org)
- [Bun Docs](https://bun.sh/docs)

---

## 🎓 Learning Outcomes

After this mission:
- ✅ Deep understanding of Android chroot environments
- ✅ Experience with mobile performance profiling
- ✅ Knowledge of thermal/battery constraints
- ✅ Practical AI agent deployment skills

---

**Mission Created**: 2026-01-18  
**Last Updated**: 2026-01-18  
**Previous Mission**: [Mission 01: Sandbox Testing](mission-01-sandbox.md)  
**Next Mission**: [Mission 03: Desktop Testing](mission-03-desktop-test.md)
