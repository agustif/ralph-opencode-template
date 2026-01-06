#!/usr/bin/env bash
set -euo pipefail
INPUT="$1"
OUTPUT="${2:-${INPUT%.*}.clean.log}"
[[ -f "$INPUT" ]] || { echo "Error: $INPUT not found" >&2; exit 1; }
sed 's/\x1b\[[0-9;]*[a-zA-Z]//g' "$INPUT" > "$OUTPUT"
echo "Converted $INPUT -> $OUTPUT"
