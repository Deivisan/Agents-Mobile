#!/usr/bin/env bash
#
# mobile-watchdog.sh - Mobile thermal and battery monitoring
#
# Monitors:
#   - CPU temperature and frequency
#   - Battery level and charging state
#   - Memory usage
#   - CPU usage per core
#
# Triggers:
#   - Throttle Bun processes when temperature > threshold
#   - Warn when battery < 20%
#   - Alert on memory pressure
#
# Usage:
#   mobile-watchdog.sh [--interval SECONDS] [--temp-threshold CELSIUS]

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Configuration
INTERVAL="${INTERVAL:-5}"          # Check every 5 seconds
TEMP_THRESHOLD="${TEMP_THRESHOLD:-75}"  # °C - start throttling
TEMP_CRITICAL="${TEMP_CRITICAL:-85}"    # °C - emergency shutdown
BATTERY_LOW="${BATTERY_LOW:-20}"        # % - low battery warning
LOG_FILE="${AGENTS_MOBILE_ROOT:-${HOME}/.agents-mobile}/logs/watchdog.log"
PID_FILE="/tmp/mobile-watchdog.pid"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --interval)
            INTERVAL="$2"
            shift 2
            ;;
        --temp-threshold)
            TEMP_THRESHOLD="$2"
            shift 2
            ;;
        --daemon)
            DAEMON=true
            shift
            ;;
        --stop)
            if [[ -f "$PID_FILE" ]]; then
                kill "$(cat "$PID_FILE")" 2>/dev/null && echo "Watchdog stopped" || echo "Watchdog not running"
                rm -f "$PID_FILE"
            fi
            exit 0
            ;;
        *)
            echo "Usage: $0 [--interval SEC] [--temp-threshold °C] [--daemon] [--stop]"
            exit 1
            ;;
    esac
done

# Ensure log directory
mkdir -p "$(dirname "$LOG_FILE")"

# Check if already running
if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo -e "${YELLOW}⚠ Watchdog already running (PID: $(cat "$PID_FILE"))${NC}"
    exit 1
fi

# Daemonize if requested
if [[ "${DAEMON:-false}" == "true" ]]; then
    echo $$ > "$PID_FILE"
    exec > "$LOG_FILE" 2>&1
fi

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Mobile Watchdog Started               ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo -e "${BLUE}Interval: ${INTERVAL}s${NC}"
echo -e "${BLUE}Temp threshold: ${TEMP_THRESHOLD}°C${NC}"
echo -e "${BLUE}Battery low: ${BATTERY_LOW}%${NC}\n"

# Get CPU temperature (Android-specific)
get_cpu_temp() {
    # Try multiple thermal zones
    for zone in /sys/class/thermal/thermal_zone*/temp; do
        if [[ -r "$zone" ]]; then
            temp=$(cat "$zone" 2>/dev/null || echo 0)
            # Convert millidegrees to degrees
            temp=$((temp / 1000))
            if [[ $temp -gt 0 ]] && [[ $temp -lt 150 ]]; then
                echo "$temp"
                return
            fi
        fi
    done
    echo "0"
}

# Get battery info (Android-specific)
get_battery_info() {
    BATTERY_PATH="/sys/class/power_supply/battery"
    
    if [[ -d "$BATTERY_PATH" ]]; then
        LEVEL=$(cat "$BATTERY_PATH/capacity" 2>/dev/null || echo "unknown")
        STATUS=$(cat "$BATTERY_PATH/status" 2>/dev/null || echo "unknown")
        echo "${LEVEL}%|${STATUS}"
    else
        echo "N/A|N/A"
    fi
}

# Get CPU frequency (MHz)
get_cpu_freq() {
    if [[ -r /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq ]]; then
        freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq)
        freq=$((freq / 1000))  # Convert kHz to MHz
        echo "$freq"
    else
        echo "0"
    fi
}

# Get memory usage
get_memory_usage() {
    if [[ -f /proc/meminfo ]]; then
        mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        mem_available=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
        mem_used=$((mem_total - mem_available))
        mem_percent=$((mem_used * 100 / mem_total))
        echo "$mem_percent"
    else
        echo "0"
    fi
}

# Get CPU usage
get_cpu_usage() {
    top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}' 2>/dev/null || echo "0"
}

# Throttle Bun processes
throttle_bun() {
    echo -e "${YELLOW}⚠ [$(date +'%H:%M:%S')] Throttling Bun processes (temp: $1°C)${NC}" | tee -a "$LOG_FILE"
    
    # Find Bun process PIDs
    BUN_PIDS=$(pgrep -f "bun" 2>/dev/null || echo "")
    
    if [[ -n "$BUN_PIDS" ]]; then
        for pid in $BUN_PIDS; do
            # Lower priority (nice value)
            renice +10 -p "$pid" >/dev/null 2>&1 || true
            
            # Limit CPU affinity (use only efficiency cores on ARM)
            # On Snapdragon 695: cores 0-5 are efficiency (A55)
            taskset -cp 0-5 "$pid" >/dev/null 2>&1 || true
        done
    fi
}

# Restore normal priority
restore_bun() {
    echo -e "${GREEN}✓ [$(date +'%H:%M:%S')] Restoring Bun processes (temp: $1°C)${NC}" | tee -a "$LOG_FILE"
    
    BUN_PIDS=$(pgrep -f "bun" 2>/dev/null || echo "")
    
    if [[ -n "$BUN_PIDS" ]]; then
        for pid in $BUN_PIDS; do
            renice 0 -p "$pid" >/dev/null 2>&1 || true
            # Use all cores
            taskset -cp 0-7 "$pid" >/dev/null 2>&1 || true
        done
    fi
}

# Emergency shutdown
emergency_shutdown() {
    echo -e "${RED}🔥 CRITICAL: Temperature $1°C - emergency shutdown!${NC}" | tee -a "$LOG_FILE"
    
    # Kill all Bun processes
    pkill -TERM -f "bun" 2>/dev/null || true
    sleep 2
    pkill -KILL -f "bun" 2>/dev/null || true
    
    # Notify user (if desktop notification available)
    if command -v termux-notification &>/dev/null; then
        termux-notification --title "Agents-Mobile Emergency" --content "Critical temperature - processes stopped"
    fi
}

# Monitoring loop
THROTTLED=false

while true; do
    # Get current stats
    TEMP=$(get_cpu_temp)
    BATTERY_INFO=$(get_battery_info)
    BATTERY_LEVEL=$(echo "$BATTERY_INFO" | cut -d'|' -f1 | tr -d '%')
    BATTERY_STATUS=$(echo "$BATTERY_INFO" | cut -d'|' -f2)
    CPU_FREQ=$(get_cpu_freq)
    MEM_USAGE=$(get_memory_usage)
    CPU_USAGE=$(get_cpu_usage)
    
    # Status line
    STATUS="${BLUE}[$(date +'%H:%M:%S')]${NC}"
    STATUS+=" 🌡️  ${TEMP}°C"
    STATUS+=" | 🔋 ${BATTERY_LEVEL}% ($BATTERY_STATUS)"
    STATUS+=" | 💾 ${MEM_USAGE}%"
    STATUS+=" | ⚡ ${CPU_FREQ}MHz"
    STATUS+=" | 📊 CPU ${CPU_USAGE}%"
    
    # Temperature checks
    if [[ $TEMP -ge $TEMP_CRITICAL ]]; then
        emergency_shutdown "$TEMP"
        break
    elif [[ $TEMP -ge $TEMP_THRESHOLD ]] && [[ "$THROTTLED" == "false" ]]; then
        throttle_bun "$TEMP"
        THROTTLED=true
        STATUS+=" ${YELLOW}[THROTTLED]${NC}"
    elif [[ $TEMP -lt $((TEMP_THRESHOLD - 5)) ]] && [[ "$THROTTLED" == "true" ]]; then
        restore_bun "$TEMP"
        THROTTLED=false
    fi
    
    # Battery warning
    if [[ "$BATTERY_LEVEL" != "unknown" ]] && [[ $BATTERY_LEVEL -lt $BATTERY_LOW ]] && [[ "$BATTERY_STATUS" != "Charging" ]]; then
        STATUS+=" ${RED}[LOW BATTERY]${NC}"
    fi
    
    # Memory pressure
    if [[ $MEM_USAGE -gt 90 ]]; then
        STATUS+=" ${RED}[HIGH MEMORY]${NC}"
    fi
    
    echo -e "$STATUS"
    
    sleep "$INTERVAL"
done

# Cleanup on exit
rm -f "$PID_FILE"
