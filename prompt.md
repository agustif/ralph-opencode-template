# RULES
- Remove tasks from prompt.md once you're 100% verifiably implemented.
- Do ONE bounded increment only.
- Minimal diff. No repo-wide churn.
- If you change code: run all VERIFIERS before finishing.
- Append one short line to `progress.log` (timestamp, what changed, what's next).
- If you are done and verifiers pass, print exactly: <promise>COMPLETE</promise>

# VERIFIERS
- ./ralph.sh run --test 1 prompt.md 2>/dev/null && echo "✓ Script runs"
- bash -n ralph.sh && echo "✓ Syntax valid"
- OVER_150=$(find . -type f -name "*.sh" 2>/dev/null | xargs wc -l 2>/dev/null | awk '$1>150 && $2!="total" {print $2" ("$1" LOC)"}'); [[ -z "$OVER_150" ]] && echo "✓ All bash files under 150 LOC" || { echo "⚠ Bash files over 150 LOC - split into modules:"; echo "$OVER_150"; exit 1; }

<promise>COMPLETE</promise>
