# TASK
Create a simple "Hello World" program in the language of your choice.

# RULES
- Do ONE bounded increment only.
- Minimal diff. No repo-wide churn.
- If you change code: run all VERIFIERS before finishing.
- Append one short line to `progress.log` (timestamp, what changed, what's next).
- If you are done and verifiers pass, print exactly: <promise>COMPLETE</promise>

# VERIFIERS
- [[ -f "hello.*" ]] && echo "✓ Program file exists"
