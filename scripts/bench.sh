#!/usr/bin/env bash
#
# bench.sh - Agents-Mobile performance benchmarking suite
#
# Measures:
#   - Bun runtime performance
#   - I/O throughput (disk read/write)
#   - CPU performance (single/multi-core)
#   - Memory bandwidth
#   - Network latency (if applicable)
#
# Outputs results in JSON and human-readable format

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
BENCH_DIR="${AGENTS_MOBILE_ROOT:-${HOME}/.agents-mobile}/benchmarks"
RESULTS_FILE="$BENCH_DIR/results-$(date +%Y%m%d-%H%M%S).json"
TMP_DIR="/tmp/agents-mobile-bench-$$"

mkdir -p "$BENCH_DIR" "$TMP_DIR"

# Banner
echo -e "${CYAN}"
cat << 'EOF'
╔══════════════════════════════════════════════════════╗
║                                                      ║
║        🔥 AGENTS-MOBILE BENCHMARK SUITE 🔥           ║
║                                                      ║
╚══════════════════════════════════════════════════════╝
EOF
echo -e "${NC}\n"

# Detect system info
detect_system() {
    echo -e "${BLUE}[0/6] Detecting system configuration...${NC}"
    
    # CPU info
    if [[ -f /proc/cpuinfo ]]; then
        CPU_MODEL=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
        CPU_CORES=$(nproc 2>/dev/null || echo "unknown")
    else
        CPU_MODEL=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "unknown")
        CPU_CORES=$(sysctl -n hw.ncpu 2>/dev/null || echo "unknown")
    fi
    
    # Memory
    if [[ -f /proc/meminfo ]]; then
        MEM_TOTAL=$(grep MemTotal /proc/meminfo | awk '{print int($2/1024)} " MB"')
    else
        MEM_TOTAL=$(sysctl -n hw.memsize 2>/dev/null | awk '{print int($1/1024/1024)} " MB"' || echo "unknown")
    fi
    
    # OS
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS_NAME="$PRETTY_NAME"
    else
        OS_NAME=$(uname -s)
    fi
    
    echo -e "${GREEN}✓ CPU: $CPU_MODEL ($CPU_CORES cores)${NC}"
    echo -e "${GREEN}✓ Memory: $MEM_TOTAL${NC}"
    echo -e "${GREEN}✓ OS: $OS_NAME${NC}\n"
}

# Benchmark 1: Bun runtime speed
bench_bun() {
    echo -e "${BLUE}[1/6] Benchmarking Bun runtime...${NC}"
    
    if ! command -v bun &>/dev/null; then
        echo -e "${RED}✗ Bun not installed - skipping${NC}"
        BUN_SCORE=0
        return
    fi
    
    # Create test script
    cat > "$TMP_DIR/bench-bun.ts" << 'EOFBUN'
// Fibonacci benchmark (CPU-intensive)
function fib(n: number): number {
    return n <= 1 ? n : fib(n - 1) + fib(n - 2);
}

// Array operations (memory-intensive)
function arrayBench(): number {
    const arr = Array.from({ length: 1000000 }, (_, i) => i);
    return arr.reduce((sum, n) => sum + n, 0);
}

// Object creation (GC pressure)
function objectBench(): number {
    let sum = 0;
    for (let i = 0; i < 100000; i++) {
        const obj = { a: i, b: i * 2, c: i * 3 };
        sum += obj.a + obj.b + obj.c;
    }
    return sum;
}

const start = performance.now();

// Run benchmarks
fib(35);
arrayBench();
objectBench();

const elapsed = performance.now() - start;
console.log(elapsed.toFixed(2));
EOFBUN
    
    # Run benchmark
    BUN_TIME=$(bun run "$TMP_DIR/bench-bun.ts" 2>/dev/null)
    BUN_SCORE=$(echo "scale=2; 10000 / $BUN_TIME" | bc -l 2>/dev/null || echo "0")
    
    echo -e "${GREEN}✓ Bun benchmark: ${BUN_TIME}ms (score: $BUN_SCORE)${NC}"
}

# Benchmark 2: Disk I/O
bench_disk_io() {
    echo -e "${BLUE}[2/6] Benchmarking disk I/O...${NC}"
    
    TEST_FILE="$TMP_DIR/io-test.bin"
    TEST_SIZE_MB=100
    
    # Write test
    echo -e "${CYAN}  Writing ${TEST_SIZE_MB}MB...${NC}"
    WRITE_START=$(date +%s.%N)
    dd if=/dev/zero of="$TEST_FILE" bs=1M count=$TEST_SIZE_MB oflag=direct 2>/dev/null
    WRITE_END=$(date +%s.%N)
    WRITE_TIME=$(echo "$WRITE_END - $WRITE_START" | bc -l)
    WRITE_SPEED=$(echo "scale=2; $TEST_SIZE_MB / $WRITE_TIME" | bc -l)
    
    # Clear cache (if possible)
    sync
    echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null 2>&1 || true
    
    # Read test
    echo -e "${CYAN}  Reading ${TEST_SIZE_MB}MB...${NC}"
    READ_START=$(date +%s.%N)
    dd if="$TEST_FILE" of=/dev/null bs=1M iflag=direct 2>/dev/null
    READ_END=$(date +%s.%N)
    READ_TIME=$(echo "$READ_END - $READ_START" | bc -l)
    READ_SPEED=$(echo "scale=2; $TEST_SIZE_MB / $READ_TIME" | bc -l)
    
    rm -f "$TEST_FILE"
    
    echo -e "${GREEN}✓ Write: ${WRITE_SPEED} MB/s${NC}"
    echo -e "${GREEN}✓ Read: ${READ_SPEED} MB/s${NC}"
}

# Benchmark 3: CPU single-thread
bench_cpu_single() {
    echo -e "${BLUE}[3/6] Benchmarking CPU (single-thread)...${NC}"
    
    # Prime number calculation
    PRIME_START=$(date +%s.%N)
    bash -c '
        count=0
        for i in {2..50000}; do
            prime=1
            for ((j=2; j*j<=i; j++)); do
                if ((i % j == 0)); then
                    prime=0
                    break
                fi
            done
            ((count += prime))
        done
        echo $count
    ' >/dev/null
    PRIME_END=$(date +%s.%N)
    PRIME_TIME=$(echo "$PRIME_END - $PRIME_START" | bc -l)
    CPU_SINGLE_SCORE=$(echo "scale=2; 100 / $PRIME_TIME" | bc -l)
    
    echo -e "${GREEN}✓ Single-thread: ${PRIME_TIME}s (score: $CPU_SINGLE_SCORE)${NC}"
}

# Benchmark 4: CPU multi-thread
bench_cpu_multi() {
    echo -e "${BLUE}[4/6] Benchmarking CPU (multi-thread)...${NC}"
    
    CORES=$(nproc 2>/dev/null || echo 1)
    
    # Parallel workload (parallel compression)
    MULTI_START=$(date +%s.%N)
    
    for i in $(seq 1 "$CORES"); do
        (
            # Generate random data and compress
            dd if=/dev/urandom bs=1M count=10 2>/dev/null | gzip > "$TMP_DIR/compress-$i.gz"
        ) &
    done
    wait
    
    MULTI_END=$(date +%s.%N)
    MULTI_TIME=$(echo "$MULTI_END - $MULTI_START" | bc -l)
    CPU_MULTI_SCORE=$(echo "scale=2; ($CORES * 10) / $MULTI_TIME" | bc -l)
    
    rm -f "$TMP_DIR"/compress-*.gz
    
    echo -e "${GREEN}✓ Multi-thread ($CORES cores): ${MULTI_TIME}s (score: $CPU_MULTI_SCORE)${NC}"
}

# Benchmark 5: Memory bandwidth
bench_memory() {
    echo -e "${BLUE}[5/6] Benchmarking memory bandwidth...${NC}"
    
    # Simple memory copy test (bash isn't ideal, but portable)
    MEM_START=$(date +%s.%N)
    
    # Allocate and write to large array
    bash -c '
        declare -a arr
        for i in {1..1000000}; do
            arr[$i]=$i
        done
    ' >/dev/null
    
    MEM_END=$(date +%s.%N)
    MEM_TIME=$(echo "$MEM_END - $MEM_START" | bc -l)
    MEM_SCORE=$(echo "scale=2; 1000 / $MEM_TIME" | bc -l)
    
    echo -e "${GREEN}✓ Memory: ${MEM_TIME}s (score: $MEM_SCORE)${NC}"
}

# Benchmark 6: Overall score
calculate_overall() {
    echo -e "${BLUE}[6/6] Calculating overall score...${NC}"
    
    # Weighted average (Bun is most important for Agents-Mobile)
    OVERALL=$(echo "scale=2; ($BUN_SCORE * 0.4) + ($CPU_SINGLE_SCORE * 0.2) + ($CPU_MULTI_SCORE * 0.2) + ($MEM_SCORE * 0.1) + ((${WRITE_SPEED:-0} + ${READ_SPEED:-0}) / 20 * 0.1)" | bc -l)
    
    echo -e "${GREEN}✓ Overall score: $OVERALL${NC}\n"
}

# Save results to JSON
save_results() {
    echo -e "${BLUE}Saving results to JSON...${NC}"
    
    cat > "$RESULTS_FILE" << EOFJSON
{
  "timestamp": "$(date -Iseconds)",
  "system": {
    "cpu": "$CPU_MODEL",
    "cores": $CPU_CORES,
    "memory": "$MEM_TOTAL",
    "os": "$OS_NAME"
  },
  "benchmarks": {
    "bun": {
      "time_ms": $BUN_TIME,
      "score": $BUN_SCORE
    },
    "disk_io": {
      "write_mb_s": ${WRITE_SPEED:-0},
      "read_mb_s": ${READ_SPEED:-0}
    },
    "cpu": {
      "single_thread": {
        "time_s": $PRIME_TIME,
        "score": $CPU_SINGLE_SCORE
      },
      "multi_thread": {
        "time_s": $MULTI_TIME,
        "score": $CPU_MULTI_SCORE,
        "cores_used": $CORES
      }
    },
    "memory": {
      "time_s": $MEM_TIME,
      "score": $MEM_SCORE
    }
  },
  "overall_score": $OVERALL
}
EOFJSON
    
    echo -e "${GREEN}✓ Results saved: $RESULTS_FILE${NC}"
}

# Print summary
print_summary() {
    cat << EOFSUMMARY

${MAGENTA}╔══════════════════════════════════════════════════════════╗
║                                                          ║
║              BENCHMARK RESULTS SUMMARY                   ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝${NC}

${CYAN}🖥️  System:${NC}
   CPU: $CPU_MODEL
   Cores: $CPU_CORES
   Memory: $MEM_TOTAL
   OS: $OS_NAME

${CYAN}⚡ Performance Scores:${NC}
   Bun Runtime:       ${GREEN}$BUN_SCORE${NC} (${BUN_TIME}ms)
   CPU Single-Thread: ${GREEN}$CPU_SINGLE_SCORE${NC}
   CPU Multi-Thread:  ${GREEN}$CPU_MULTI_SCORE${NC} ($CORES cores)
   Memory:            ${GREEN}$MEM_SCORE${NC}
   Disk Write:        ${GREEN}${WRITE_SPEED:-N/A} MB/s${NC}
   Disk Read:         ${GREEN}${READ_SPEED:-N/A} MB/s${NC}

${YELLOW}🏆 OVERALL SCORE: ${OVERALL}${NC}

${BLUE}📊 Comparison:${NC}
   Score > 50  : Excellent (Desktop-class)
   Score 20-50 : Good (Mobile high-end)
   Score 10-20 : Fair (Mobile mid-range)
   Score < 10  : Needs optimization

${BLUE}📁 Full results:${NC} $RESULTS_FILE

EOFSUMMARY
}

# Cleanup
cleanup() {
    rm -rf "$TMP_DIR"
}

trap cleanup EXIT

# Main execution
main() {
    detect_system
    bench_bun
    bench_disk_io
    bench_cpu_single
    bench_cpu_multi
    bench_memory
    calculate_overall
    save_results
    print_summary
}

main "$@"
