# 🚀 Agents-Mobile Core Aliases
# Add this to your ~/.zshrc or ~/.bashrc

# === Navigation ===
alias agents="cd /sdcard/Agents-Mobile"
alias skills="cd /sdcard/Agents-Mobile/skills"
alias missions="cd /sdcard/Agents-Mobile/missions"

# === Chroot Management ===
alias arch="bash ~/start-arch.sh"
alias archroot="bash ~/start-arch.sh"
alias enter-arch="bash ~/start-arch.sh"

# === Bun Shortcuts ===
alias b="bun"
alias br="bun run"
alias bi="bun install"
alias ba="bun add"
alias bt="bun test"
alias bb="bun build"

# === AI Agents ===
alias claude="bash /sdcard/Agents-Mobile/scripts/claude.sh"
alias gemini="gemini-cli"
alias ask="bash /sdcard/Agents-Mobile/scripts/ask-agent.sh"

# === Testing ===
alias test-install="bash /sdcard/Agents-Mobile/tests/test-install.sh"
alias test-mounts="sudo bash /sdcard/Agents-Mobile/tests/test-mounts.sh"
alias test-all="bash /sdcard/Agents-Mobile/tests/test-install.sh && sudo bash /sdcard/Agents-Mobile/tests/test-mounts.sh"

# === Performance Monitoring ===
alias monitor="bash /sdcard/Agents-Mobile/scripts/mobile-watchdog.sh"
alias perf="bash /sdcard/Agents-Mobile/scripts/bench.sh"
alias temp="cat /sys/class/thermal/thermal_zone0/temp | awk '{print \$1/1000 \"°C\"}'"
alias battery="termux-battery-status | jq -r '.percentage'"

# === Quick Info ===
alias info-cpu="cat /proc/cpuinfo"
alias info-mem="free -h"
alias info-device="bash /sdcard/Agents-Mobile/setup/detect.sh"

# === Git Shortcuts (for contributing) ===
alias gs="git status"
alias ga="git add"
alias gc="git commit -m"
alias gp="git push"
alias gl="git log --oneline --graph -10"

# === Skill Loader ===
# Load a skill and show its contents
skill() {
    local skill_name="$1"
    if [[ -z "$skill_name" ]]; then
        echo "📚 Available skills:"
        ls /sdcard/Agents-Mobile/skills/*.md | xargs -n1 basename
        return
    fi
    
    local skill_path="/sdcard/Agents-Mobile/skills/${skill_name}.md"
    if [[ -f "$skill_path" ]]; then
        bat "$skill_path" || cat "$skill_path"
    else
        echo "❌ Skill not found: $skill_name"
        echo "Available:"
        ls /sdcard/Agents-Mobile/skills/*.md | xargs -n1 basename
    fi
}

# === Mission Picker ===
mission() {
    local mission_name="$1"
    if [[ -z "$mission_name" ]]; then
        echo "🎯 Available missions:"
        ls /sdcard/Agents-Mobile/missions/*.md | xargs -n1 basename
        return
    fi
    
    local mission_path="/sdcard/Agents-Mobile/missions/${mission_name}.md"
    if [[ -f "$mission_path" ]]; then
        bat "$mission_path" || cat "$mission_path"
    else
        echo "❌ Mission not found: $mission_name"
        echo "Available:"
        ls /sdcard/Agents-Mobile/missions/*.md | xargs -n1 basename
    fi
}

# === Quick Log ===
log() {
    local message="$1"
    local logfile="/sdcard/Agents-Mobile/logs/user-$(date +%Y%m%d).log"
    mkdir -p /sdcard/Agents-Mobile/logs
    echo "[$(date -Iseconds)] $message" >> "$logfile"
    echo "✅ Logged to $logfile"
}

# === Thermal Management ===
cooldown() {
    local temp=$(cat /sys/class/thermal/thermal_zone0/temp)
    if [[ $temp -gt 70000 ]]; then
        echo "🔥 Device hot ($((temp/1000))°C) - pausing processes..."
        pkill -STOP bun
        sleep 30
        pkill -CONT bun
        echo "✅ Resumed after cooldown"
    else
        echo "✅ Temperature OK ($((temp/1000))°C)"
    fi
}

# === Smart Bun (battery-aware) ===
smart-bun() {
    local battery=$(termux-battery-status | jq -r '.percentage')
    
    if [[ $battery -lt 30 ]]; then
        echo "🔋 Low battery ($battery%) - eco mode"
        export BUN_JSC_useJIT=false
        nice -n 19 bun run "$@"
    elif [[ $battery -lt 70 ]]; then
        echo "⚡ Medium battery ($battery%) - balanced"
        nice -n 10 bun run "$@"
    else
        echo "✅ Full battery ($battery%) - performance mode"
        taskset -c 6,7 bun run "$@"
    fi
}

# === Quick Benchmark ===
bench-quick() {
    echo "⚡ Quick Benchmark"
    echo ""
    echo "CPU:"
    time bun -e "Array(1000000).fill(0).map((_, i) => i * 2)"
    echo ""
    echo "I/O:"
    time bun -e "await Bun.write('/tmp/bench.dat', new Uint8Array(10*1024*1024))"
    rm /tmp/bench.dat
}

# === Environment Info ===
agents-info() {
    echo "📱 Agents-Mobile Environment"
    echo "============================"
    echo ""
    echo "Device: $(getprop ro.product.model || echo 'Unknown')"
    echo "Android: $(getprop ro.build.version.release || echo 'N/A')"
    echo "Kernel: $(uname -r)"
    echo "CPU: $(cat /proc/cpuinfo | grep 'model name' | head -n1 | cut -d: -f2 | xargs)"
    echo "Cores: $(nproc)"
    echo "RAM: $(free -h | awk '/^Mem:/ {print $2}')"
    echo "Battery: $(termux-battery-status 2>/dev/null | jq -r '.percentage' || echo 'N/A')%"
    echo "Temp: $(($(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0)/1000))°C"
    echo ""
    echo "Bun: $(bun --version 2>/dev/null || echo 'Not installed')"
    echo "Git: $(git --version 2>/dev/null || echo 'Not installed')"
    echo ""
    echo "Agents-Mobile: $(git -C /sdcard/Agents-Mobile describe --tags 2>/dev/null || echo 'v1.0-dev')"
}

# === Update Agents-Mobile ===
agents-update() {
    cd /sdcard/Agents-Mobile
    echo "🔄 Updating Agents-Mobile..."
    git pull origin master
    echo "✅ Updated to latest version"
    agents-info
}

# === Export All Functions ===
# (for bash compatibility)
export -f skill 2>/dev/null || true
export -f mission 2>/dev/null || true
export -f log 2>/dev/null || true
export -f cooldown 2>/dev/null || true
export -f smart-bun 2>/dev/null || true
export -f bench-quick 2>/dev/null || true
export -f agents-info 2>/dev/null || true
export -f agents-update 2>/dev/null || true

# === Welcome Message ===
echo "🤖 Agents-Mobile aliases loaded!"
echo "   Type 'agents-info' for environment details"
echo "   Type 'skill' to list available skills"
echo "   Type 'mission' to list active missions"
