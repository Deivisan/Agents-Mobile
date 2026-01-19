# 📊 Hardware Compatibility Matrix

This document lists tested devices and their compatibility with Agents-Mobile.

---

## ✅ Fully Tested

| Device | CPU | RAM | Android | Root | Status | Performance | Notes |
|--------|-----|-----|---------|------|--------|-------------|-------|
| **Poco X5 5G** | Snapdragon 695 (A78+A55) | 8GB | 13 | ✅ Yes | ✅ Excellent | +30% CPU, +15% I/O | Reference device |

---

## 🟡 Community Tested

*Waiting for community contributions - see [Mission 02](../missions/mission-02-android-test.md)*

| Device | CPU | RAM | Android | Root | Status | Tester | Notes |
|--------|-----|-----|---------|------|--------|--------|-------|
| - | - | - | - | - | - | - | Awaiting tests |

---

## Recommended Specifications

### Minimum

- **CPU**: ARM64 (ARMv8-A or newer)
- **RAM**: 4GB physical + 4GB ZRAM
- **Storage**: 16GB free
- **Android**: 9+ (API level 28+)
- **Root**: Optional (but recommended for performance)

### Recommended

- **CPU**: Snapdragon 600-series or better (or Dimensity/Exynos equivalent)
- **RAM**: 6-8GB physical + 8GB ZRAM
- **Storage**: 32GB+ free
- **Android**: 11+ (API level 30+)
- **Root**: Magisk installed
- **Custom ROM**: LineageOS, PixelExperience, or similar

### Optimal

- **CPU**: Snapdragon 8-series (e.g., SD 888, 8 Gen 1/2)
- **RAM**: 12GB+ physical
- **Storage**: 128GB+ UFS 3.1
- **Android**: 13+
- **Root**: Yes (Magisk with Zygisk)
- **Kernel**: Custom kernel with ZRAM, KSM, F2FS support

---

## CPU Architecture Support

| Architecture | Status | Notes |
|--------------|--------|-------|
| **ARM64 (aarch64)** | ✅ Full Support | Primary target |
| **ARMv7 (32-bit)** | ⚠️ Limited | Bun may not work on old ARMv7 |
| **x86_64** | ✅ Works (via WSL/Emulator) | Desktop testing only |
| **x86 (32-bit)** | ❌ Not Supported | Too old |

---

## Chipset Compatibility

### Snapdragon (Qualcomm)

| Series | Performance | Notes |
|--------|-------------|-------|
| **8 Gen 3** | Excellent | Flagship, very fast |
| **8 Gen 2** | Excellent | 2023 flagship |
| **8 Gen 1** | Excellent | 2022 flagship |
| **888/870** | Excellent | 2021 flagship |
| **7 Gen 2/3** | Very Good | Mid-range 2023-2024 |
| **695** | Good | Reference (Poco X5 5G) |
| **680/685** | Moderate | Entry mid-range |
| **400-series** | Limited | Low-end, may struggle |

### MediaTek Dimensity

| Series | Performance | Notes |
|--------|-------------|-------|
| **9000/9200** | Excellent | Flagship competitor |
| **8000/8200** | Very Good | Upper mid-range |
| **7000** | Good | Mid-range |
| **6000** | Moderate | Entry mid-range |

### Samsung Exynos

| Series | Performance | Notes |
|--------|-------------|-------|
| **2400/2200** | Excellent | Flagship (S24/S23) |
| **2100/990** | Very Good | S21/S20 |
| **1280/1380** | Good | A-series |
| **850** | Moderate | Entry level |

### Google Tensor

| Series | Performance | Notes |
|--------|-------------|-------|
| **G4** | Excellent | Pixel 9 |
| **G3** | Very Good | Pixel 8 |
| **G2/G1** | Good | Pixel 7/6 |

---

## RAM Recommendations

| Physical RAM | ZRAM | Total Effective | Workload |
|--------------|------|-----------------|----------|
| 4GB | 4GB | 8GB | Light (simple scripts) |
| 6GB | 6GB | 12GB | Moderate (AI agents) |
| 8GB | 8GB | 16GB | Heavy (MCP + multiple agents) |
| 12GB+ | 8GB | 20GB+ | Professional (compiling, large models) |

---

## Storage Types

| Type | Speed | Status | Notes |
|------|-------|--------|-------|
| **UFS 4.0** | Very Fast | ✅ Excellent | Latest flagship |
| **UFS 3.1** | Fast | ✅ Excellent | Common in 2021+ |
| **UFS 2.1/2.2** | Moderate | ✅ Good | Sufficient |
| **eMMC 5.1** | Slow | ⚠️ Limited | Old devices, slow I/O |
| **SD Card** | Very Slow | ❌ Not Recommended | Too slow for chroot |

---

## Android Version Compatibility

| Android | API Level | Status | Notes |
|---------|-----------|--------|-------|
| **14** | 34 | ✅ Full Support | Latest |
| **13** | 33 | ✅ Full Support | Tested (Poco X5 5G) |
| **12/12L** | 31-32 | ✅ Full Support | Stable |
| **11** | 30 | ✅ Supported | Minimum recommended |
| **10** | 29 | ⚠️ Limited | Older Termux may be needed |
| **9 (Pie)** | 28 | ⚠️ Limited | Minimum, may have issues |
| **8 or older** | <28 | ❌ Not Supported | Too old |

---

## Desktop Environments

| OS | Status | Notes |
|-----|--------|-------|
| **WSL2 (Windows)** | ✅ Full Support | Use Ubuntu or Arch |
| **Linux (native)** | ✅ Full Support | Arch, Ubuntu, Debian tested |
| **macOS (Apple Silicon)** | ✅ Works | ARM64 native |
| **macOS (Intel)** | ⚠️ Limited | x86 emulation slower |
| **Chrome OS** | 🔄 Untested | May work via Linux container |

---

## Emulators

| Emulator | Status | Notes |
|----------|--------|-------|
| **Android Studio AVD** | ✅ Works | Use ARM64 system image |
| **Genymotion** | ⚠️ Limited | May not have root |
| **Bluestacks** | ❌ Not Recommended | x86 translation layer |

---

## Root Methods

| Method | Status | Notes |
|--------|--------|-------|
| **Magisk** | ✅ Recommended | Most compatible |
| **KernelSU** | ✅ Good | Kernel-level root |
| **SuperSU** | ⚠️ Outdated | Old method, avoid |
| **No Root (proot)** | ⚠️ Limited | -30% performance |

---

## Known Issues

### Snapdragon 695 (Poco X5 5G)

- ✅ Works perfectly with native chroot
- ⚠️ Thermal throttling at 70°C+ (use `mobile-debug.md` watchdog)
- ✅ ZRAM support excellent
- ✅ Bun stable with `/dev/shm` tmpfs mount

### Low RAM Devices (<6GB)

- ⚠️ May need to reduce Bun `--max-old-space-size`
- ⚠️ Disable JIT: `export BUN_JSC_useJIT=false`
- ⚠️ Use Claude Haiku instead of Sonnet (lower memory)

### Old Android (<11)

- ⚠️ Termux from F-Droid may have compatibility issues
- ⚠️ ZRAM may not be available
- ❌ Some modern Bun features may not work

---

## How to Contribute

Tested Agents-Mobile on your device? Add your results!

1. Run `bash setup/detect.sh` and save output
2. Run `bash tests/test-install.sh` and save log
3. Run benchmarks: `bash scripts/bench.sh`
4. Fork this repo
5. Add your device to "Community Tested" table
6. Submit PR with logs

**Template**:

```markdown
| Device Name | CPU | RAM | Android | Root | Status | Tester | Notes |
| Your Device | CPU Model | XGB | XX | Yes/No | Excellent/Good/Limited | @yourusername | Brief notes |
```

---

## Benchmark Comparison

*Reference: Poco X5 5G (Snapdragon 695, 8GB RAM, Android 13, Magisk root)*

| Test | Termux (vanilla) | Agents-Mobile (chroot) | Improvement |
|------|------------------|------------------------|-------------|
| CPU (sysbench) | 3.2s | 2.4s | **+33%** |
| I/O Write (100MB) | 1.8s | 1.5s | **+20%** |
| I/O Read (100MB) | 1.2s | 1.0s | **+20%** |
| Bun cold start | 0.5s | 0.3s | **+67%** |
| TypeScript compile | 1.1s | 0.8s | **+38%** |

Your device may perform better or worse depending on hardware!

---

**Last Updated**: 2026-01-18  
**Next Update**: After community testing (Mission 02)
