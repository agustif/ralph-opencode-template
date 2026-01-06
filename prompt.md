# WORKFLOW
Loop through these phases until complete:

## PHASE 1: PLAN
- Review current state and what needs to be done
- Check docs/features/ for accepted suggestions to implement
- Prioritize next action (highest priority, smallest scope first)
- Document the plan in progress.log
- Move to IMPLEMENT phase

## PHASE 2: IMPLEMENT
- Do ONE bounded increment only
- Minimal diff. No repo-wide churn
- Follow the plan from PHASE 1
- Move to REVIEW phase after implementation

## PHASE 3: REVIEW
- Run all VERIFIERS
- Check if implementation matches the plan
- Verify code quality and correctness
- Update progress.log with results
- If verifiers pass and work is complete: print <promise>COMPLETE</promise>
- If verifiers fail: document issue and return to PLAN phase
- If more work needed: return to PLAN phase for next increment

# RULES
- Remove tasks from prompt.md once you're 100% verifiably implemented
- Always cycle: PLAN → IMPLEMENT → REVIEW → (repeat or COMPLETE)
- In PLAN phase: be specific about what you'll do next
- In IMPLEMENT phase: focus only on the planned work
- In REVIEW phase: be thorough in verification
- Append one short line to `progress.log` after each phase (timestamp, phase, what changed, what's next)
- If you are done and verifiers pass, print exactly: <promise>COMPLETE</promise>

# VERIFIERS
- ./ralph.sh run --test 1 prompt.md 2>/dev/null && echo "✓ Script runs"
- bash -n ralph.sh && echo "✓ Syntax valid"
- OVER_150=$(find . -type f -name "*.sh" 2>/dev/null | xargs wc -l 2>/dev/null | awk '$1>150 && $2!="total" {print $2" ("$1" LOC)"}'); [[ -z "$OVER_150" ]] && echo "✓ All bash files under 150 LOC" || { echo "⚠ Bash files over 150 LOC - split into modules:"; echo "$OVER_150"; exit 1; }
- SHELL_FILES=$(find . -type f -name "*.sh" ! -path "./.git/*" ! -path "./.crush/*" ! -path "./.ruff_cache/*" 2>/dev/null | sed 's|^\./||' | sort | tr '\n' ' ' | xargs); EXPECTED="install.sh ralph.sh"; [[ "$SHELL_FILES" == "$EXPECTED" ]] && echo "✓ Only ralph.sh and install.sh exist" || { echo "⚠ Unexpected shell files found:"; echo "$SHELL_FILES"; echo "Expected only: $EXPECTED"; exit 1; }
