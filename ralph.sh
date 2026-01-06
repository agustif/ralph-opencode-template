#!/usr/bin/env bash
# Re-execute with bash if run with sh
[ -z "${BASH_VERSION:-}" ] && exec bash "$0" "$@"
set -euo pipefail

PROMISE_TOKEN="<promise>COMPLETE</promise>"

# strip_ansi - Remove ANSI escape codes from text
strip_ansi() { sed 's/\x1b\[[0-9;]*[a-zA-Z]//g'; }

# json_escape - Convert text to JSON-safe string
json_escape() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\t/\\t/g' -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\n/g'; }

# cmd_run - Main ralph loop execution
cmd_run() {
    TEST_MODE=""
    YOLO_MODE="true"
    JSON_MODE="false"
    if [[ "${1:-}" == "--test" ]]; then
        TEST_MODE="true"
        shift
    fi
    if [[ "${1:-}" == "--no-yolo" ]]; then
        YOLO_MODE=""
        shift
    fi
    if [[ "${1:-}" == "--json" ]]; then
        JSON_MODE="true"
        shift
    fi
    if [[ $# -gt 0 && ! $1 =~ ^[0-9]+$ ]]; then
        echo "Usage: $0 [--test] [--no-yolo] [--json] [turns] [spec] [model]" >&2
        exit 1
    fi
    N="${1:-50}"
    [[ "$N" -ge 1 && "$N" -le 1000 ]] || { echo "Turns must be between 1 and 1000"; exit 1; }
    SPEC="${2:-prompt.md}"
    MODEL="${3:-opencode/glm-4.7-free}"
    LOG="${LOG:-.ralph.log}"
    [[ ! "$LOG" =~ \.\. ]] || { echo "Path traversal not allowed in LOG path: $LOG" >&2; echo "Use absolute or relative paths without '..'" >&2; exit 1; }
    JSONL="${LOG}.jsonl"
    TIMEOUT="${TIMEOUT:-300}"
    [[ "$MODEL" =~ ^[a-zA-Z0-9._/-]+$ ]] && [[ ! "$MODEL" =~ \.\. ]] || { echo "Invalid model name"; exit 1; }
    [[ "$TIMEOUT" =~ ^[0-9]+$ && "$TIMEOUT" -ge 10 && "$TIMEOUT" -le 3600 ]] || { echo "Timeout must be between 10 and 3600 seconds"; exit 1; }
    [[ ! "$SPEC" =~ \.\. ]] || { echo "Path traversal not allowed: $SPEC" >&2; echo "Use absolute or relative paths without '..'" >&2; exit 1; }
    [[ -r "$SPEC" ]] || { echo "Spec file not readable: $SPEC" >&2; echo "Create $SPEC or specify a different file" >&2; echo "Example: $0 run my-task.md" >&2; exit 1; }
    
    grep -q "No task" "$SPEC" && exit 0
    for f in "$LOG" "$JSONL"; do
        d=$(dirname "$f")
        mkdir -p "$d" && [[ -w "$d" ]] || { echo "Cannot write to log directory: $d"; exit 1; }
    done
    : > "$LOG"
    : > "$JSONL"
    OPENCODE_PATH=$(command -v opencode 2>/dev/null) || { echo "opencode not found in PATH" >&2; echo "Install from: https://opencode.ai" >&2; exit 1; }
    [[ -x "$OPENCODE_PATH" ]] || { echo "opencode not executable: $OPENCODE_PATH" >&2; echo "Install from: https://opencode.ai" >&2; exit 1; }
    for i in $(seq 1 "$N"); do
        TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        INSTRUCTION="Turn $i. Follow $SPEC exactly."
        [[ "$YOLO_MODE" == "true" ]] && INSTRUCTION="$INSTRUCTION If no specific task provided, auto-plan and create new tasks as needed."
        if [[ "$TEST_MODE" == "true" ]]; then
            OUTPUT="Test mode - simulated output for turn $i$PROMISE_TOKEN"
            echo "$OUTPUT"
        else
            TMPOUT=$(mktemp)
            trap 'rm -f "$TMPOUT" 2>/dev/null; exit 130' INT TERM
            timeout "$TIMEOUT" opencode run "$INSTRUCTION" --file "$SPEC" -m "$MODEL" 2>&1 | tee "$TMPOUT" || true
            OUTPUT=$(strip_ansi < "$TMPOUT")
            rm -f "$TMPOUT"
            trap - INT TERM
        fi
        OUTPUT_ESCAPED=$(json_escape "$OUTPUT")
        JSON_RECORD="{\"turn\":$i,\"status\":\"completed\",\"timestamp\":\"$TS\",\"output\":\"$OUTPUT_ESCAPED\"}"
        echo "$JSON_RECORD" >> "$JSONL"
        if [[ "$JSON_MODE" == "true" ]]; then
            echo "$JSON_RECORD" | tee -a "$LOG"
        else
            echo "Turn $i..." >> "$LOG"
            echo "$OUTPUT" >> "$LOG"
        fi
        (grep -q "$PROMISE_TOKEN" "$LOG" 2>/dev/null || grep -q "$PROMISE_TOKEN" "$JSONL" 2>/dev/null) && exit 0
    done
    exit 1
}

# Main dispatcher
case "${1:-run}" in
    run|--test|--no-yolo|--json) shift; cmd_run "$@" ;;
    [0-9]*) cmd_run "$@" ;;
    *) echo "Usage: $0 [args...]" >&2; exit 1 ;;
esac
