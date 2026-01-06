#!/usr/bin/env bash
set -euo pipefail

# Input validation
[[ $# -eq 0 || $1 =~ ^[0-9]+$ ]] || { echo "Usage: $0 [iterations] [spec] [model]"; exit 1; }
N="${1:-50}"
SPEC="${2:-prompt.md}"
MODEL="${3:-opencode/glm-4.7-free}"
LOG="${LOG:-.ralph.log}"

# Sanitize model name (prevent shell injection)
MODEL=$(printf '%s' "$MODEL" | tr -d ';&|`$(){}[]<>')

# Check spec exists
[[ -f "$SPEC" ]] || { echo "Spec file not found: $SPEC"; exit 1; }

# Loop with timeout and proper error handling
for i in $(seq 1 "$N"); do
    echo "Iteration $i..." | tee -a "$LOG"
    if timeout 300 opencode run "Iteration $i. Follow $SPEC exactly." --file "$SPEC" -m "$MODEL" >> "$LOG" 2>&1; then
        grep -q "<promise>COMPLETE</promise>" "$LOG" && exit 0
    fi
done
exit 1
