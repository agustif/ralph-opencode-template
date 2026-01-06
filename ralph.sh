#!/usr/bin/env bash
set -euo pipefail
N="${1:-50}"; SPEC="${2:-prompt.md}"; MODEL="${3:-opencode/glm-4.7-free}"; LOG="${LOG:-.ralph.log}"
for i in $(seq 1 "$N"); do
  opencode run "Iteration $i. Follow $SPEC exactly." --file "$SPEC" -m "$MODEL" | tee -a "$LOG" >/dev/null || true
  grep -q "<promise>COMPLETE</promise>" "$LOG" && exit 0
done
exit 1
