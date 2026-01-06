#!/usr/bin/env bash
# Re-execute with bash if run with sh
[ -z "${BASH_VERSION:-}" ] && exec bash "$0" "$@"
set -euo pipefail

# strip_ansi - Remove ANSI escape codes from text
strip_ansi() { sed 's/\x1b\[[0-9;]*[a-zA-Z]//g'; }

# json_escape - Convert text to JSON-safe string
json_escape() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\t/\\t/g' -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\n/g'; }

# cmd_convert - Convert log file to remove ANSI codes
cmd_convert() {
    if [[ $# -lt 1 ]]; then
        echo "Usage: $0 convert <log_file> [output_file]" >&2
        exit 1
    fi
    INPUT="$1"
    OUTPUT="${2:-${INPUT%.*}.clean.log}"
    [[ ! -f "$INPUT" ]] && { echo "Error: $INPUT not found" >&2; exit 1; }
    strip_ansi < "$INPUT" > "$OUTPUT"
    echo "Converted $INPUT -> $OUTPUT"
}

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
        echo "Usage: $0 [--test] [--no-yolo] [--json] [Turns] [spec] [model]" >&2
        exit 1
    fi
    N="${1:-50}"
    [[ "$N" -ge 1 && "$N" -le 1000 ]] || { echo "Turns must be between 1 and 1000"; exit 1; }
    SPEC="${2:-prompt.md}"
    MODEL="${3:-opencode/glm-4.7-free}"
    LOG="${LOG:-.ralph.log}"
    [[ ! "$LOG" =~ \.\. ]] || { echo "Path traversal not allowed in LOG path"; exit 1; }
    JSONL="${LOG}.jsonl"
    TIMEOUT="${TIMEOUT:-300}"
    [[ "$MODEL" =~ ^[a-zA-Z0-9._/-]+$ ]] && [[ ! "$MODEL" =~ \.\. ]] || { echo "Invalid model name"; exit 1; }
    [[ "$TIMEOUT" =~ ^[0-9]+$ && "$TIMEOUT" -ge 10 && "$TIMEOUT" -le 3600 ]] || { echo "Timeout must be between 10 and 3600 seconds"; exit 1; }
    [[ ! "$SPEC" =~ \.\. ]] || { echo "Path traversal not allowed"; exit 1; }
    [[ -r "$SPEC" ]] || { echo "Spec file not readable: $SPEC"; exit 1; }
    grep -q "No task" "$SPEC" && exit 0
    for f in "$LOG" "$JSONL"; do
        d=$(dirname "$f")
        mkdir -p "$d" && [[ -w "$d" ]] || { echo "Cannot write to log directory: $d"; exit 1; }
    done
    : > "$LOG"
    : > "$JSONL"
    command -v opencode >/dev/null 2>&1 || { echo "opencode not found in PATH"; exit 1; }
    for i in $(seq 1 "$N"); do
        TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        INSTRUCTION="Turn $i. Follow $SPEC exactly."
        [[ "$YOLO_MODE" == "true" ]] && INSTRUCTION="$INSTRUCTION If no specific task provided, auto-plan and create new tasks as needed."
        if [[ "$TEST_MODE" == "true" ]]; then
            OUTPUT="Test mode - simulated output for turn $i<promise>COMPLETE</promise>"
            echo "$OUTPUT"
        else
            TMPOUT=$(mktemp)
            timeout "$TIMEOUT" opencode run "$INSTRUCTION" --file "$SPEC" -m "$MODEL" 2>&1 | tee "$TMPOUT" || true
            OUTPUT=$(strip_ansi < "$TMPOUT")
            rm -f "$TMPOUT"
        fi
        OUTPUT_ESCAPED=$(json_escape "$OUTPUT")
        JSON_RECORD="{\"turn\":$i,\"status\":\"completed\",\"timestamp\":\"$TS\",\"output\":\"$OUTPUT_ESCAPED\"}"
        echo "$JSON_RECORD" >> "$JSONL"
        [[ "$JSON_MODE" == "true" ]] && echo "$JSON_RECORD" | tee -a "$LOG" || { echo "Turn $i..." >> "$LOG"; echo "$OUTPUT" >> "$LOG"; }
        (grep -q "<promise>COMPLETE</promise>" "$LOG" 2>/dev/null || grep -q "<promise>COMPLETE</promise>" "$JSONL" 2>/dev/null) && exit 0
    done
    exit 1
}

# Main dispatcher
case "${1:-run}" in
    convert) shift; cmd_convert "$@" ;;
    run|--test|--no-yolo|--json) shift; cmd_run "$@" ;;
    [0-9]*) cmd_run "$@" ;;
    *) echo "Usage: $0 [run|convert] [args...]" >&2; echo "  run     - Run ralph loop (default)" >&2; echo "  convert - Convert log file to remove ANSI codes" >&2; exit 1 ;;
esac
