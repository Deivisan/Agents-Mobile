# ⚡ Performance Guide - Agents-Mobile

## Overview

This document details performance characteristics, benchmarks, and optimization strategies for Agents-Mobile across different platforms.

## Benchmark Methodology

Our benchmark suite (`scripts/bench.sh`) measures:

1. **Bun Runtime Performance** - JavaScript/TypeScript execution speed
2. **Disk I/O** - Sequential read/write throughput
3. **CPU Single-Thread** - Prime number calculation (single core)
4. **CPU Multi-Thread** - Parallel compression (all cores)
5. **Memory Bandwidth** - Large array allocation/access

### Running Benchmarks

```bash
cd ~/.agents-mobile/scripts
./bench.sh
```

Results are saved to: `~/.agents-mobile/benchmarks/results-TIMESTAMP.json`

---

## Reference Performance

### Mobile Devices

#### Poco X5 5G (Snapdragon 695, 8GB RAM, Arch Chroot)
```
✅ TESTED - 2026-01-18

Overall Score: 42.5
├─ Bun Runtime: 58.3 (1,718ms)
├─ CPU Single:  38.2 (2.62s)
├─ CPU Multi:   45.8 (1.75s, 8 cores)
├─ Memory:      32.1 (31.1s)
└─ Disk I/O:    Write 85 MB/s, Read 120 MB/s

Notes:
- Native chroot gives +30% performance vs vanilla Termux
- Kernel optimizations (PGO, BOLT, LTO) add +10-15%
- 8GB ZRAM swap allows heavy workloads
```

#### Samsung Galaxy S21 (Exynos 2100, 8GB RAM)
```
⏳ PENDING - Awaiting community testing

Expected Score: ~45-50
├─ Bun Runtime: ~65 (faster CPU)
├─ CPU Multi:   ~55 (better scheduler)
├─ Disk I/O:    ~100/150 MB/s (UFS 3.1)
```

---

### Desktop/Laptop

#### WSL 2 (AMD Ryzen 7 5700G, 16GB RAM, Windows 11)
```
⏳ PENDING - Mission 03

Expected Score: ~80-100
├─ Bun Runtime: ~100+ (desktop-class CPU)
├─ CPU Multi:   ~90 (16 threads)
├─ Disk I/O:    ~300/500 MB/s (NVMe SSD)
```

#### macOS M1 (Apple Silicon, 16GB RAM)
```
⏳ PENDING - Awaiting community testing

Expected Score: ~120+
├─ Bun Runtime: ~150+ (ARM optimized)
├─ CPU Multi:   ~110 (unified memory)
├─ Disk I/O:    ~1500/2000 MB/s (integrated SSD)
```

#### Linux Native (Intel i7-12700K, 32GB RAM)
```
⏳ PENDING - Awaiting community testing

Expected Score: ~100-120
├─ Bun Runtime: ~120+
├─ CPU Multi:   ~100 (20 threads)
├─ Disk I/O:    ~500/700 MB/s (SATA SSD)
```

---

## Score Interpretation

| Score Range | Classification | Description |
|-------------|----------------|-------------|
| **100+** | 🔥 Extreme | Desktop workstation class |
| **70-100** | 🚀 Excellent | High-end desktop/laptop |
| **50-70** | ⚡ Very Good | Mid-range desktop / flagship mobile |
| **30-50** | ✅ Good | Entry desktop / high-end mobile |
| **20-30** | 🆗 Fair | Mid-range mobile |
| **<20** | ⚠️ Limited | Low-end mobile / needs optimization |

---

## Optimization Strategies

### For Mobile (Score <50)

#### 1. Use Native Chroot (vs PRoot)
**Impact**: +30% overall performance

```bash
# Check if rooted
su -c "id"

# If root available, use install.sh instead of install-proot.sh
su -c "bash setup/install.sh"
```

#### 2. Optimize Kernel Governor
**Impact**: +10-15% CPU performance

```bash
# Check current governor
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# Set to performance (requires root)
su -c "echo performance > /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor"
```

#### 3. Enable ZRAM Swap
**Impact**: Allows larger workloads, prevents OOM

```bash
# Create 8GB ZRAM (adjust to device RAM)
su -c "
  modprobe zram num_devices=1
  echo 8G > /sys/block/zram0/disksize
  mkswap /dev/zram0
  swapon /dev/zram0 -p 10
"
```

#### 4. Thermal Management
**Impact**: Prevents throttling during benchmarks

```bash
# Start watchdog before heavy work
./scripts/mobile-watchdog.sh --daemon --temp-threshold 70

# Run benchmark
./scripts/bench.sh

# Stop watchdog
./scripts/mobile-watchdog.sh --stop
```

#### 5. Disable Background Apps
**Impact**: +5-10% available resources

```bash
# Termux (via Android settings)
Settings → Apps → See all apps → [Disable unused apps]

# Or via CLI (requires root)
su -c "pm disable com.facebook.katana"  # Example: Facebook
```

---

### For Desktop (Score <70)

#### 1. Use Native Linux (vs WSL)
**Impact**: +15-20% I/O performance

WSL 2 has filesystem overhead. If possible, dual-boot or use native Linux.

#### 2. Upgrade to NVMe SSD
**Impact**: 3-5x disk I/O improvement

```bash
# Check current disk type
lsblk -d -o name,rota

# ROTA 1 = HDD (rotating disk)
# ROTA 0 = SSD (upgrade if HDD)
```

#### 3. Enable CPU Performance Mode
**Impact**: +10% CPU benchmarks

```bash
# Linux
sudo cpupower frequency-set -g performance

# macOS (disable power throttling)
sudo pmset -a hibernatemode 0
sudo pmset -a disablesleep 1
```

#### 4. Allocate More RAM (if VM)
**Impact**: Prevents memory pressure

```bash
# WSL 2: Edit .wslconfig
cat > ~/.wslconfig << 'EOF'
[wsl2]
memory=16GB
processors=8
swap=4GB
EOF

# Restart WSL
wsl --shutdown
```

#### 5. Close Resource-Heavy Apps
**Impact**: +10-20% available CPU/RAM

```bash
# Check resource usage
htop

# Kill heavy processes
pkill chrome  # Example
```

---

## Bun-Specific Optimizations

### 1. Enable JIT Compiler
**Impact**: +20-30% runtime performance

```bash
export BUN_JSC_useJIT=1
bun run app.ts
```

### 2. Use Native Modules
**Impact**: 2-10x speedup for heavy computation

```typescript
// Bad: Pure JavaScript
function sha256(data: string): string {
  // JS implementation (slow)
}

// Good: Native Bun API
import { hash } from "bun";
const result = hash("sha256", data);  // Native C++ (fast)
```

### 3. Optimize Transpilation
**Impact**: Faster startup, smaller bundles

```bash
# Create bunfig.toml
cat > bunfig.toml << 'EOF'
[build]
target = "bun"
minify = true
sourcemap = "none"

[install]
optional = false
dev = false
EOF
```

### 4. Use Bun's Built-in APIs
**Impact**: Avoid dependencies, reduce bundle size

```typescript
// Instead of node:fs
import { file } from "bun";
const data = await file("data.json").text();

// Instead of node-fetch
const response = await fetch("https://api.com");

// Instead of dotenv
const key = Bun.env.API_KEY;
```

### 5. Bundle for Production
**Impact**: 50-80% smaller size, faster load

```bash
# Development (no optimization)
bun run dev

# Production (optimized)
bun build ./src/index.ts \
  --outdir ./dist \
  --minify \
  --target bun \
  --splitting
```

---

## Memory Optimization

### 1. Monitor Usage
```bash
# Real-time monitoring
./scripts/mobile-watchdog.sh

# Or manually
free -h
cat /proc/meminfo
```

### 2. Limit Bun Memory
```bash
# Set max heap size (e.g., 2GB)
bun --max-old-space-size=2048 run app.ts
```

### 3. Use Streaming
```typescript
// Bad: Load entire file in memory
const data = await Bun.file("large.json").json();

// Good: Stream processing
const file = Bun.file("large.json");
const stream = file.stream();

for await (const chunk of stream) {
  // Process incrementally
}
```

---

## Disk I/O Optimization

### 1. Use tmpfs for Temporary Files
**Impact**: 10-100x faster I/O

```bash
# Create tmpfs mount (RAM disk)
sudo mount -t tmpfs -o size=1G tmpfs /tmp/agents-mobile

# Use for builds/cache
bun build --outdir /tmp/agents-mobile/dist
```

### 2. Reduce Write Amplification
```bash
# Disable access time updates
sudo mount -o remount,noatime /
```

### 3. Use Bulk Operations
```typescript
// Bad: Multiple small writes
for (const item of items) {
  await Bun.write(`file-${item.id}.json`, JSON.stringify(item));
}

// Good: Single large write
await Bun.write("data.json", JSON.stringify(items));
```

---

## Network Optimization (for API-heavy workloads)

### 1. Use HTTP/2 or HTTP/3
```typescript
// Bun supports HTTP/2 by default
const server = Bun.serve({
  port: 3000,
  fetch(req) {
    return new Response("Hello");
  }
});
```

### 2. Enable Compression
```typescript
import { gzipSync } from "bun";

const server = Bun.serve({
  fetch(req) {
    const data = JSON.stringify(largeObject);
    const compressed = gzipSync(data);
    
    return new Response(compressed, {
      headers: { "Content-Encoding": "gzip" }
    });
  }
});
```

### 3. Cache Aggressively
```typescript
const cache = new Map();

const server = Bun.serve({
  fetch(req) {
    const url = req.url;
    
    if (cache.has(url)) {
      return cache.get(url);
    }
    
    const response = new Response("data");
    cache.set(url, response.clone());
    return response;
  }
});
```

---

## Profiling Tools

### CPU Profiling
```bash
# Bun built-in profiler
bun --cpu-profile run app.ts

# Analyze with Chrome DevTools
# chrome://inspect → Load profile
```

### Memory Profiling
```bash
# Heap snapshot
bun --heap-snapshot run app.ts

# Analyze with Chrome DevTools
```

### I/O Profiling
```bash
# Linux: iotop (requires root)
sudo iotop -o

# Bun internal metrics
bun run --smol app.ts  # Low memory mode
```

---

## Continuous Monitoring

### Setup Watchdog (Mobile)
```bash
# Start on boot (Termux)
cat > ~/.termux/boot/watchdog.sh << 'EOF'
#!/bin/bash
~/.agents-mobile/scripts/mobile-watchdog.sh --daemon
EOF

chmod +x ~/.termux/boot/watchdog.sh
```

### Automated Benchmarks
```bash
# Daily benchmark via cron (Desktop)
crontab -e

# Add:
0 3 * * * /home/user/.agents-mobile/scripts/bench.sh >> /home/user/bench.log 2>&1
```

---

## Community Contributions

Submit your benchmarks to help others!

**How to submit**:
1. Run `./scripts/bench.sh`
2. Copy JSON from `~/.agents-mobile/benchmarks/`
3. Create issue: https://github.com/Deivisan/Agents-Mobile/issues
4. Title: `[Benchmark] Device Name - Score XX`
5. Paste JSON + device specs

We'll add validated results to this document.

---

## Future Optimizations

Planned improvements:

- [ ] **GPU Acceleration** - Leverage mobile GPU for compute
- [ ] **AOT Compilation** - Pre-compile Bun bundles
- [ ] **Profile-Guided Optimization** - Custom Bun builds per device
- [ ] **Distributed Computing** - Multi-device workload sharing
- [ ] **Edge Caching** - Local LLM result caching

---

**Last Updated**: 2026-01-18  
**Contributors**: Deivison Santana (@deivisan)  
**Community Benchmarks**: 1 (Poco X5 5G)
