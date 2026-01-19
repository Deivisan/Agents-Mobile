---
name: Mobile Debug & Optimization
description: Detect thermal throttling, monitor battery, optimize performance on mobile devices
when_to_use: When device is slow, hot, or draining battery during AI agent operations
difficulty: Intermediate
requires: Android with Termux, root access (optional)
---

# 📱 Mobile Debug & Optimization Skill

This skill teaches AI agents how to **debug and optimize mobile device performance** during intensive tasks.

## Why This Matters

Mobile devices have unique constraints:
- 🔥 **Thermal throttling** - CPU slows when hot
- 🔋 **Battery drain** - Intensive tasks kill battery fast
- 💾 **RAM limits** - OOM kills can crash processes
- 📶 **Network instability** - Mobile connections drop

## Detection Commands

### 1. Check CPU Temperature

```bash
# Android (requires root or Termux API)
cat /sys/class/thermal/thermal_zone*/temp

# Example output: 45000 (= 45°C)
```

### 2. Monitor Battery

```bash
# Termux API
termux-battery-status

# Output (JSON):
# {
#   "health": "GOOD",
#   "percentage": 75,
#   "temperature": 32.4,
#   "status": "DISCHARGING"
# }
```

### 3. Check CPU Frequency (Throttling)

```bash
# Current frequency
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq

# Maximum possible frequency
cat /sys/devices/system/cpu/cpu*/cpufreq/cpuinfo_max_freq

# If cur_freq << max_freq → throttling active
```

### 4. Memory Usage

```bash
# Total memory
free -h

# Process-specific
top -b -n 1 | head -n 20

# Find memory hogs
ps aux --sort=-%mem | head -n 10
```

### 5. Active Processes

```bash
# All running processes
ps aux

# Bun processes specifically
ps aux | grep bun

# Kill if needed
pkill -9 bun
```

## Optimization Strategies

### Strategy 1: Thermal Management

```bash
# If temp > 70°C, pause heavy tasks
TEMP=$(cat /sys/class/thermal/thermal_zone0/temp)
if [[ $TEMP -gt 70000 ]]; then
    echo "🔥 Device too hot! Pausing tasks..."
    pkill -STOP bun  # Pause Bun processes
    sleep 30         # Wait for cooldown
    pkill -CONT bun  # Resume
fi
```

### Strategy 2: Battery-Aware Execution

```bash
# Only run heavy tasks if battery > 50%
BATTERY=$(termux-battery-status | jq -r '.percentage')

if [[ $BATTERY -lt 50 ]]; then
    echo "🔋 Low battery! Switching to lite mode..."
    export BUN_RUNTIME_TRANSPILER_CACHE_PATH="/dev/null"  # Disable cache
    export NODE_OPTIONS="--max-old-space-size=512"         # Limit RAM
else
    echo "✅ Battery OK, full performance mode"
fi
```

### Strategy 3: CPU Affinity (Performance Cores Only)

```bash
# Snapdragon 695 has 2 fast cores (CPU 6-7) + 6 slow cores (CPU 0-5)
# Pin Bun to fast cores
taskset -c 6,7 bun run script.ts
```

### Strategy 4: ZRAM Monitoring

```bash
# Check ZRAM usage
cat /proc/swaps

# If ZRAM is full, clear caches
if [[ $(cat /proc/swaps | grep zram | awk '{print $4}') -gt 7000000 ]]; then
    echo "💾 ZRAM high, clearing caches..."
    sync
    echo 3 > /proc/sys/vm/drop_caches  # Requires root
fi
```

### Strategy 5: Network Monitoring

```bash
# Check if online
ping -c 1 8.8.8.8 &> /dev/null

if [[ $? -ne 0 ]]; then
    echo "📶 Network down! Switching to offline mode..."
    export OFFLINE_MODE=true
fi
```

## Automated Watchdog Script

Create `scripts/mobile-watchdog.sh`:

```bash
#!/bin/bash
# Monitors device health and auto-optimizes

INTERVAL=10  # Check every 10 seconds

while true; do
    # Get metrics
    TEMP=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0)
    BATTERY=$(termux-battery-status 2>/dev/null | jq -r '.percentage' || echo 100)
    
    # Thermal check
    if [[ $TEMP -gt 70000 ]]; then
        echo "🔥 Thermal throttling detected! Pausing tasks..."
        pkill -STOP bun
        sleep 30
        pkill -CONT bun
    fi
    
    # Battery check
    if [[ $BATTERY -lt 20 ]]; then
        echo "🔋 Critical battery! Stopping all tasks..."
        pkill bun
        break
    fi
    
    # Memory check
    MEM_PERCENT=$(free | grep Mem | awk '{print ($3/$2) * 100}')
    if (( $(echo "$MEM_PERCENT > 90" | bc -l) )); then
        echo "💾 High memory usage! Clearing caches..."
        sync
        echo 1 > /proc/sys/vm/drop_caches 2>/dev/null
    fi
    
    sleep $INTERVAL
done
```

Usage:

```bash
# Run in background
bash scripts/mobile-watchdog.sh &

# Check if running
ps aux | grep watchdog
```

## Agent-Specific Optimizations

### For Claude Code / OpenCode

```bash
# Limit context window on low battery
if [[ $BATTERY -lt 50 ]]; then
    export OPENCODE_MAX_CONTEXT=8000  # Reduce from default 200k
fi
```

### For Bun Scripts

```bash
# Reduce memory footprint
export BUN_JSC_useJIT=false          # Disable JIT on low RAM
export BUN_GARBAGE_COLLECTOR_LEVEL=1 # Aggressive GC
```

## Diagnostics

### Find What's Draining Battery

```bash
# Top CPU consumers
top -b -n 1 -o %CPU | head -n 20

# Top memory consumers
top -b -n 1 -o %MEM | head -n 20

# Network usage (requires root)
cat /proc/net/dev
```

### Log Performance

```bash
# Create performance log
cat > logs/perf-$(date +%Y%m%d-%H%M%S).log <<EOF
Timestamp: $(date -Iseconds)
CPU Temp: $(cat /sys/class/thermal/thermal_zone0/temp)
Battery: $(termux-battery-status | jq -r '.percentage')%
RAM Free: $(free -h | grep Mem | awk '{print $4}')
Swap Used: $(free -h | grep Swap | awk '{print $3}')
EOF
```

## Troubleshooting

| Issue | Detection | Solution |
|-------|-----------|----------|
| Device hot | Temp > 70°C | Pause tasks, wait 30s |
| Battery draining | < 50% | Lite mode, reduce context |
| Out of memory | RAM > 90% | Clear caches, kill unused processes |
| CPU throttling | cur_freq << max_freq | Pin to performance cores |
| Network drops | Ping fails | Enable offline mode |

## Real-World Example

```bash
#!/bin/bash
# Smart Bun execution with mobile optimizations

# Pre-flight checks
TEMP=$(cat /sys/class/thermal/thermal_zone0/temp)
BATTERY=$(termux-battery-status | jq -r '.percentage')

if [[ $TEMP -gt 65000 ]] || [[ $BATTERY -lt 30 ]]; then
    echo "⚠️  Suboptimal conditions, running in lite mode..."
    taskset -c 0-5 nice -n 10 bun run script.ts  # Slow cores, low priority
else
    echo "✅ Full power mode"
    taskset -c 6,7 bun run script.ts  # Performance cores
fi
```

---

**Skill Level**: Intermediate  
**Estimated Time**: 15-30 minutes  
**Prerequisites**: Termux, basic bash  
**Agent Compatibility**: All (requires shell access)

## Next Steps

- Set up automated alerts (email/push when throttling)
- Create Grafana dashboard for metrics
- Integrate with AI agent decision-making (auto-pause on thermal)
