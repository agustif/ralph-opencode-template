# Ralph - Improvement Suggestions

## Overview
This document provides prioritized, actionable recommendations for improving ralph.sh and the overall repository based on analysis of code quality, security, performance, user experience, documentation, and feature gaps.

---

## Priority 1: Critical Security & Safety Improvements

### 1.1 Enhance Model Name Validation
**Location:** ralph.sh:54

**Issue:** Current regex `^[a-zA-Z0-9._/-]+$` is too permissive and could allow injection attacks.

**Recommendation:**
```bash
# Replace line 54 with stricter validation
[[ "$MODEL" =~ ^[a-zA-Z0-9][a-zA-Z0-9._/-]*[a-zA-Z0-9]$ ]] && [[ ! "$MODEL" =~ \.\. ]] || { echo "Invalid model name format"; exit 1; }
```

**Rationale:** Prevents leading/trailing special characters and reduces attack surface while maintaining flexibility for valid model names.

### 1.2 Add Temp File Cleanup on Interrupt
**Location:** ralph.sh:74-77

**Issue:** Temp files aren't cleaned up if script is interrupted (SIGINT/SIGTERM).

**Recommendation:**
```bash
# Add trap handler at beginning of cmd_run
trap 'rm -f "$TMPOUT" 2>/dev/null; exit 130' INT TERM

# Wrap temp file usage
TMPOUT=$(mktemp)
trap 'rm -f "$TMPOUT" 2>/dev/null; exit 130' INT TERM
timeout "$TIMEOUT" opencode run "$INSTRUCTION" --file "$SPEC" -m "$MODEL" 2>&1 | tee "$TMPOUT" || true
OUTPUT=$(strip_ansi < "$TMPOUT")
rm -f "$TMPOUT"
trap - INT TERM
```

**Rationale:** Prevents disk pollution from orphaned temp files during interruptions.

### 1.3 Validate Spec File Size and Type
**Location:** ralph.sh:57

**Issue:** No validation of spec file size or type - could cause resource exhaustion.

**Recommendation:**
```bash
# Add after line 57
SPEC_SIZE=$(stat -c%s "$SPEC" 2>/dev/null || stat -f%z "$SPEC" 2>/dev/null)
[[ "$SPEC_SIZE" -gt 1048576 ]] && { echo "Spec file too large (>1MB): $SPEC"; exit 1; }
[[ "$SPEC" == *.md ]] || [[ "$SPEC" == *.txt ]] || { echo "Spec file must be .md or .txt: $SPEC"; exit 1; }
```

**Rationale:** Prevents memory issues from large files and ensures expected file types.

### 1.4 Add Binary Verification for opencode
**Location:** ralph.sh:65

**Issue:** No verification that opencode command is actually the expected tool.

**Recommendation:**
```bash
# Enhance line 65 check
OPENCODE_PATH=$(command -v opencode 2>/dev/null) || { echo "opencode not found in PATH"; exit 1; }
[[ -x "$OPENCODE_PATH" ]] || { echo "opencode not executable: $OPENCODE_PATH"; exit 1; }
# Optional: add hash verification if you distribute known-good binaries
```

**Rationale:** Prevents confusion from shadowed binaries or PATH manipulation attacks.

---

## Priority 2: Code Quality & Maintainability

### 2.1 Extract Constants to Top of Script
**Location:** ralph.sh

**Issue:** Magic strings and values scattered throughout script.

**Recommendation:**
```bash
# Add at top after shebang
RALPH_VERSION="1.0.0"
PROMISE_TOKEN="<promise>COMPLETE</promise>"
DEFAULT_TURNS=50
DEFAULT_MODEL="opencode/glm-4.7-free"
DEFAULT_SPEC="prompt.md"
DEFAULT_LOG=".ralph.log"
DEFAULT_TIMEOUT=300
MIN_TIMEOUT=10
MAX_TIMEOUT=3600
MIN_TURNS=1
MAX_TURNS=1000
MAX_SPEC_SIZE=1048576

# Replace magic strings with constants throughout
# Example: line 68-69
INSTRUCTION="Turn $i. Follow $SPEC exactly."
[[ "$YOLO_MODE" == "true" ]] && INSTRUCTION="$INSTRUCTION If no specific task provided, auto-plan and create new tasks as needed."

# Example: line 83
(grep -q "$PROMISE_TOKEN" "$LOG" 2>/dev/null || grep -q "$PROMISE_TOKEN" "$JSONL" 2>/dev/null) && exit 0
```

**Rationale:** Improves maintainability, reduces typos, makes configuration changes easier.

### 2.2 Consolidate ANSI Stripping Functions
**Location:** ralph.sh:7 and convert_log.sh:6

**Issue:** Duplicate ANSI stripping logic in two places.

**Recommendation:**
```bash
# Remove convert_log.sh (it's redundant)
# Source strip_ansi function in ralph.sh only
# Or create a shared utils.sh:
# utils.sh
strip_ansi() { sed 's/\x1b\[[0-9;]*[a-zA-Z]//g'; }
json_escape() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\t/\\t/g' -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\n/g'; }

# In ralph.sh, source it:
# SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# source "$SCRIPT_DIR/utils.sh"
```

**Rationale:** Eliminates duplication, ensures consistent behavior, reduces maintenance burden.

### 2.3 Improve Error Messages with Context
**Location:** Multiple error messages throughout

**Issue:** Error messages lack guidance for resolution.

**Recommendation:**
```bash
# Example for line 65
[[ -x "$OPENCODE_PATH" ]] || { echo "opencode not executable: $OPENCODE_PATH" >&2; echo "Install from: https://opencode.ai" >&2; exit 1; }

# Example for line 51-52
[[ ! "$LOG" =~ \.\. ]] || { echo "Path traversal not allowed in LOG path: $LOG" >&2; echo "Use absolute or relative paths without '..'" >&2; exit 1; }

# Example for line 48-49
SPEC="${2:-$DEFAULT_SPEC}"
[[ ! -f "$SPEC" ]] && { echo "Spec file not found: $SPEC" >&2; echo "Create $SPEC or specify a different file" >&2; echo "Example: $0 run my-task.md" >&2; exit 1; }
```

**Rationale:** Helps users resolve issues faster without external help.

### 2.4 Add Logging Configuration at Startup
**Location:** cmd_run function start

**Issue:** No visibility into what configuration is being used.

**Recommendation:**
```bash
# Add after validation section, before main loop
echo "=== Ralph $RALPH_VERSION ==="
echo "Config:"
echo "  Turns: $N"
echo "  Spec: $SPEC"
echo "  Model: $MODEL"
echo "  Log: $LOG"
echo "  Timeout: ${TIMEOUT}s"
echo "  Modes: Test=$TEST_MODE, YOLO=$YOLO_MODE, JSON=$JSON_MODE"
echo "========================="
```

**Rationale:** Provides visibility into configuration, helps debugging, documents what was run.

### 2.5 Add Shellcheck Compliance
**Location:** All shell scripts

**Issue:** No automated shell script quality checking.

**Recommendation:**
1. Add `.shellcheckrc` file:
```ini
# .shellcheckrc
disable=SC2086,SC2154
exclude=SC1090
```

2. Add Makefile target:
```makefile
shellcheck:
	shellcheck ralph.sh install.sh convert_log.sh

lint: shellcheck test
```

3. Add CI configuration (if applicable):
```yaml
# .github/workflows/shellcheck.yml
name: ShellCheck
on: [push, pull_request]
jobs:
  shellcheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: ludeeus/action-shellcheck@master
```

**Rationale:** Catches common shell script bugs before they cause issues, improves code quality.

---

## Priority 3: Performance Optimizations

### 3.1 Cache Command Existence Checks
**Location:** ralph.sh:65

**Issue:** opencode check happens every run (though only once per execution).

**Current State:** Already optimal - runs once per script invocation.

**Recommendation:** No change needed, but document this optimization in comments:
```bash
# Check once at startup - cached for all iterations
command -v opencode >/dev/null 2>&1 || { echo "opencode not found in PATH"; exit 1; }
```

**Rationale:** Documents optimization decision, prevents premature refactoring.

### 3.2 Optimize Promise Token Search
**Location:** ralph.sh:83

**Issue:** Grep scans entire log files on every iteration.

**Recommendation:**
```bash
# Track promise token status in a variable
PROMISE_FOUND="false"

# Inside the loop after writing output
if grep -q "$PROMISE_TOKEN" <<< "$OUTPUT"; then
    PROMISE_FOUND="true"
    break
fi

# At end of loop
[[ "$PROMISE_FOUND" == "true" ]] && exit 0
```

**Rationale:** Avoids O(n*m) complexity, much faster for long runs.

### 3.3 Add Progress Reporting Option
**Location:** cmd_run loop

**Issue:** No progress indication for long-running turns.

**Recommendation:**
```bash
# Add flag handling
if [[ "${1:-}" == "--progress" ]]; then
    PROGRESS_MODE="true"
    shift
fi

# Inside the loop, during opencode execution
if [[ "$PROGRESS_MODE" == "true" ]] && [[ "$TEST_MODE" != "true" ]]; then
    timeout "$TIMEOUT" opencode run "$INSTRUCTION" --file "$SPEC" -m "$MODEL" 2>&1 | \
        while IFS= read -r line; do
            echo "$line" | tee -a "$TMPOUT"
            # Simple progress indicator based on opencode output patterns
            case "$line" in
                *"Complete"*) echo -ne "\rProgress: $i/$N ✓" ;;
                *"Error"*) echo -ne "\rProgress: $i/$N ✗" ;;
                *) echo -ne "\rRunning: $i/$N..." ;;
            esac
        done
    echo  # New line after loop
else
    # Original behavior
    timeout "$TIMEOUT" opencode run "$INSTRUCTION" --file "$SPEC" -m "$MODEL" 2>&1 | tee "$TMPOUT" || true
fi
```

**Rationale:** Provides feedback during long operations without adding significant overhead.

---

## Priority 4: User Experience & Usability

### 4.1 Add Verbose/Quiet Modes
**Location:** cmd_run function

**Issue:** All users get same output level, no way to reduce verbosity.

**Recommendation:**
```bash
# Add mode flags
VERBOSE=""
QUIET=""
if [[ "${1:-}" == "--verbose" ]] || [[ "${1:-}" == "-v" ]]; then
    VERBOSE="true"
    shift
fi
if [[ "${1:-}" == "--quiet" ]] || [[ "${1:-}" == "-q" ]]; then
    QUIET="true"
    shift
fi

# Wrap output with conditionals
[[ -z "$QUIET" ]] && echo "Turn $i..."

# Only show detailed info in verbose mode
[[ "$VERBOSE" == "true" ]] && echo "Using model: $MODEL, spec: $SPEC"
```

**Rationale:** Allows tailoring output for different use cases (CI/CD, interactive, scripting).

### 4.2 Add Summary Statistics
**Location:** After loop completion

**Issue:** No summary of what was accomplished.

**Recommendation:**
```bash
# Add after loop exits (before exit 0 or 1)
if [[ "$TEST_MODE" != "true" ]]; then
    DURATION=$(( $(date +%s) - START_TIME ))
    LOG_LINES=$(wc -l < "$LOG" 2>/dev/null || echo 0)
    LOG_SIZE=$(stat -c%s "$LOG" 2>/dev/null || stat -f%z "$LOG" 2>/dev/null || echo 0)
    
    echo ""
    echo "=== Summary ==="
    echo "Total turns: $i"
    echo "Duration: ${DURATION}s"
    echo "Log file: $LOG (${LOG_SIZE} bytes, ${LOG_LINES} lines)"
    echo "Output: $([[ -f "$JSONL" ]] && wc -l < "$JSONL" || echo 0) JSON records"
    echo "=============="
fi
```

**Rationale:** Provides closure and useful metrics for optimization.

### 4.3 Add Help Command
**Location:** Main dispatcher

**Issue:** Help is minimal and only shown on error.

**Recommendation:**
```bash
# Add case for help
case "${1:-run}" in
    help|--help|-h) 
        cat << 'EOF'
Ralph - OpenCode Loop Harness v1.0.0

USAGE:
    ralph.sh [COMMAND] [OPTIONS]

COMMANDS:
    run [turns] [spec] [model]     Run ralph loop (default)
    convert <input> [output]       Convert log file (remove ANSI)
    help                           Show this help message

OPTIONS:
    --test                         Test mode (simulate output)
    --no-yolo                      Disable auto-planning
    --json                         JSON output mode
    --progress                     Show progress during turns
    --verbose, -v                  Verbose output
    --quiet, -q                    Quiet mode

EXAMPLES:
    ralph.sh 50 my-task.md                 # Run 50 turns with custom spec
    ralph.sh run --test 1 prompt.md        # Test with 1 turn
    ralph.sh --json --progress 100         # JSON mode with progress
    ralph.sh convert .ralph.log clean.log  # Clean ANSI codes

CONFIGURATION:
    LOG        Path to log file (default: .ralph.log)
    TIMEOUT    Opencode timeout in seconds (default: 300)
EOF
        exit 0
        ;;
    convert) shift; cmd_convert "$@" ;;
    run|--test|--no-yolo|--json|--progress|--verbose|--quiet|-v|-q) shift; cmd_run "$@" ;;
    [0-9]*) cmd_run "$@" ;;
    *) echo "Unknown command: $1" >&2; echo "Run 'ralph.sh help' for usage" >&2; exit 1 ;;
esac
```

**Rationale:** Makes the tool self-documenting and discoverable.

### 4.4 Add Config File Support
**Location:** Create new file

**Issue:** Command-line only configuration, no way to save common settings.

**Recommendation:**
```bash
# Add to cmd_run function start
# Try to load config from .ralphrc in current directory or home
RALPH_RC=""
if [[ -f ".ralphrc" ]]; then
    RALPH_RC=".ralphrc"
elif [[ -f "$HOME/.ralphrc" ]]; then
    RALPH_RC="$HOME/.ralphrc"
fi

if [[ -n "$RALPH_RC" ]]; then
    # Simple key=value parsing
    while IFS='=' read -r key value; do
        [[ "$key" =~ ^[[:space:]]*# ]] && continue  # Skip comments
        [[ -z "$key" ]] && continue  # Skip empty lines
        key=$(echo "$key" | xargs)  # Trim whitespace
        value=$(echo "$value" | xargs)
        eval "$key='$value'"
    done < "$RALPH_RC"
fi

# Example .ralphrc file:
# RALPH_TURNS=100
# RALPH_MODEL=opencode/claude-3-opus
# RALPH_TIMEOUT=600
# RALPH_VERBOSE=true
```

**Rationale:** Allows project-specific and user-specific configurations.

---

## Priority 5: Documentation & Testing

### 5.1 Add Comprehensive README
**Location:** README.md

**Issue:** Current README is minimal, lacks detailed usage examples and troubleshooting.

**Recommendation:**
```markdown
# Ralph Code

[Detailed description as currently, then add:]

## Installation

### Option 1: Install Script
```bash
curl -fsSL https://raw.githubusercontent.com/agustif/ralph-opencode-template/main/install.sh | bash
```

### Option 2: Manual Install
```bash
git clone https://github.com/agustif/ralph-opencode-template.git
cd ralph-opencode-template
chmod +x ralph.sh
ln -s $(pwd)/ralph.sh ~/.local/bin/ralph  # Optional
```

## Detailed Usage

### Running Tasks

#### Basic Usage
```bash
./ralph.sh 50 prompt.md
```

#### With Custom Model
```bash
./ralph.sh 100 my-task.md opencode/gpt-4
```

#### Test Mode (Simulated)
```bash
./ralph.sh --test 1 prompt.md
```

#### JSON Output
```bash
./ralph.sh --json 50 prompt.md > output.jsonl
```

### Understanding the Spec Format

Your spec file (e.g., prompt.md) should contain:
- **TASK**: What you want to accomplish
- **RULES**: How the agent should behave
- **VERIFIERS**: How to verify completion

Example:
```markdown
# TASK
Create a Python script that processes CSV files.

# RULES
- Use standard library only
- Handle errors gracefully
- Add docstrings

# VERIFIERS
- [[ -f "process_csv.py" ]] && echo "✓ Script exists"
- python3 -m py_compile process_csv.py && echo "✓ Syntax valid"
```

### Understanding Logs

- `.ralph.log`: Human-readable log with full output
- `.ralph.log.jsonl`: Machine-readable JSON log per turn
- `progress.log`: Optional progress tracking

### Troubleshooting

#### "opencode not found in PATH"
Install OpenCode CLI: https://opencode.ai

#### "Spec file not readable"
Ensure the file exists and has read permissions:
```bash
ls -la prompt.md
```

#### Timeout errors
Increase timeout with environment variable:
```bash
TIMEOUT=600 ./ralph.sh 50 prompt.md
```

#### Loop doesn't stop
Ensure your spec includes verifiers and the agent prints:
```
<promise>COMPLETE</promise>
```

## Development

### Running Tests
```bash
make test
```

### Checking Shell Script Quality
```bash
make shellcheck
```

### Adding New Features
1. Edit ralph.sh
2. Update this README
3. Add verifiers to prompt.md
4. Run tests: `make test`

## Contributing
[Add contribution guidelines]
```

**Rationale:** Reduces onboarding time, reduces support burden, increases adoption.

### 5.2 Add Unit Tests
**Location:** Create tests/ directory

**Issue:** No automated testing beyond syntax check.

**Recommendation:**
```bash
# tests/test_ralph.sh
#!/usr/bin/env bash
set -euo pipefail

# Source the main script functions
RALPH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$RALPH_DIR/ralph.sh"

# Test strip_ansi
test_strip_ansi() {
    local input=$'\x1b[31mRed text\x1b[0m'
    local output=$(strip_ansi <<< "$input")
    [[ "$output" == "Red text" ]] || { echo "strip_ansi failed"; return 1; }
    echo "✓ strip_ansi"
}

# Test json_escape
test_json_escape() {
    local input='Hello "world"'
    local output=$(json_escape "$input")
    [[ "$output" == 'Hello \"world\"' ]] || { echo "json_escape failed"; return 1; }
    echo "✓ json_escape"
}

# Test path validation
test_path_traversal() {
    # Should reject paths with ..
    LOG="../../../etc/passwd"
    [[ ! "$LOG" =~ \.\. ]] || { echo "Path traversal detection failed"; return 1; }
    echo "✓ Path traversal detection"
}

# Run all tests
main() {
    echo "Running ralph unit tests..."
    test_strip_ansi
    test_json_escape
    test_path_traversal
    echo "All tests passed!"
}

main "$@"
```

Add to Makefile:
```makefile
test-unit:
	bash tests/test_ralph.sh

test: test-unit
	@./ralph.sh run --test 1 prompt.md 2>/dev/null && echo "✓ Script runs"
	@bash -n ralph.sh && echo "✓ Syntax valid"
```

**Rationale:** Catches regressions, documents expected behavior, enables refactoring.

### 5.3 Add Integration Tests
**Location:** tests/integration/

**Issue:** No end-to-end testing.

**Recommendation:**
```bash
# tests/integration/test_basic_workflow.sh
#!/usr/bin/env bash
set -euo pipefail

TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

cd "$TEST_DIR"

# Initialize a minimal task
cat > prompt.md << 'EOF'
# TASK
Create a file named "test.txt" with content "Hello, World!"

# RULES
- Minimal diff
- If done, print exactly: <promise>COMPLETE</promise>
EOF

# Copy ralph.sh to test directory
cp "$(dirname "${BASH_SOURCE[0]}")/../../ralph.sh" .

# Run ralph in test mode
LOG="$TEST_DIR/.ralph.log"
timeout 30 ./ralph.sh --test 1 prompt.md > "$LOG" 2>&1

# Verify completion
grep -q "<promise>COMPLETE</promise>" "$LOG" || { echo "Test failed: completion token not found"; exit 1; }

# Verify file created
[[ -f "test.txt" ]] || { echo "Test failed: output file not created"; exit 1; }

echo "✓ Integration test passed"
```

Add to Makefile:
```makefile
test-integration:
	bash tests/integration/test_basic_workflow.sh

test-all: test-unit test-integration
```

**Rationale:** Validates real-world behavior, catches integration issues.

### 5.4 Add Example Specs
**Location:** examples/ directory

**Issue:** Limited examples for new users.

**Recommendation:**
Create several example specs:

`examples/simple-task.md`:
```markdown
# TASK
Create a simple "Hello World" program in Python.

# RULES
- Do ONE bounded increment only.
- Minimal diff. No repo-wide churn.
- If you change code: run all VERIFIERS before finishing.
- If you are done and verifiers pass, print exactly: <promise>COMPLETE</promise>

# VERIFIERS
- [[ -f "hello.py" ]] && echo "✓ Program file exists"
- python3 hello.py | grep -q "Hello, World" && echo "✓ Output correct"
```

`examples/research-task.md`:
```markdown
# TASK
Research the best practices for shell scripting in 2025.

# SCOPE
- Focus on bash scripting
- Include security considerations
- Include modern tools and techniques

# SEED LIST
- Security best practices
- Performance optimizations
- Testing frameworks
- Modern bash features

# RULES
- Remove items from SEED LIST as they're completed
- Add new items discovered during research
- Save findings to docs/research/[topic].md
- Minimal output - focus on key insights
- If done, print exactly: <promise>COMPLETE</promise>

# VERIFIERS
- [[ -d "docs/research" ]] && echo "✓ Research directory exists"
- [[ $(find docs/research -name "*.md" 2>/dev/null | wc -l) -gt 0 ]] && echo "✓ Research files created"
```

`examples/code-refactor.md`:
```markdown
# TASK
Refactor the following function to improve readability and maintainability.

# RULES
- Preserve all functionality
- Add comments explaining changes
- Run all VERIFIERS before finishing
- If done, print exactly: <promise>COMPLETE</promise>

# VERIFIERS
- [[ -f "refactored.py" ]] && echo "✓ Refactored file exists"
- python3 -m py_compile refactored.py && echo "✓ Syntax valid"
- bash -n ralph.sh && echo "✓ ralph.sh still valid"
```

**Rationale:** Provides starting points, demonstrates best practices, reduces learning curve.

---

## Priority 6: Feature Gaps & Enhancements

### 6.1 Add Resume Capability
**Location:** cmd_run function

**Issue:** Cannot resume from interrupted runs, loses progress.

**Recommendation:**
```bash
# Add --resume flag
if [[ "${1:-}" == "--resume" ]]; then
    RESUME_MODE="true"
    # Find last completed turn from JSONL
    if [[ -f "$JSONL" ]]; then
        LAST_TURN=$(tail -1 "$JSONL" | grep -o '"turn":[0-9]*' | cut -d: -f2)
        LAST_TURN=$((LAST_TURN + 1))
        echo "Resuming from turn $LAST_TURN"
        for i in $(seq "$LAST_TURN" "$N"); do
            # ... rest of loop
        done
    else
        echo "No previous run found, starting fresh"
    fi
    shift
fi
```

**Rationale:** Saves time and resources when runs are interrupted, improves reliability.

### 6.2 Add Turn Skipping
**Location:** cmd_run loop

**Issue:** No way to skip problematic turns without restarting.

**Recommendation:**
```bash
# Add --skip flag with turn numbers
SKIPS=""
if [[ "${1:-}" == "--skip" ]]; then
    shift
    SKIPS="$1"
    shift
fi

# In loop, skip specified turns
for i in $(seq 1 "$N"); do
    if [[ "$SKIPS" =~ (^|,)$i(,|$) ]]; then
        echo "Skipping turn $i"
        continue
    fi
    # ... rest of loop
done
```

**Rationale:** Allows handling problematic turns without losing all progress.

### 6.3 Add Parallel Execution Option
**Location:** cmd_run loop

**Issue:** Sequential only, cannot leverage multiple CPUs or API rate limits.

**Recommendation:**
```bash
# Add --parallel flag with job count
PARALLEL_JOBS=1
if [[ "${1:-}" == "--parallel" ]]; then
    shift
    PARALLEL_JOBS="${1:-4}"
    [[ "$PARALLEL_JOBS" =~ ^[0-9]+$ ]] || { echo "Parallel jobs must be a number"; exit 1; }
    shift
fi

# Use GNU parallel or xargs
if [[ "$PARALLEL_JOBS" -gt 1 ]]; then
    echo "Running in parallel with $PARALLEL_JOBS jobs"
    seq 1 "$N" | parallel -j "$PARALLEL_JOBS" --line-buffer bash -c '
        i=$1
        TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        INSTRUCTION="Turn $i. Follow '"$SPEC"' exactly."
        OUTPUT=$(timeout '"$TIMEOUT"' opencode run "$INSTRUCTION" --file '"$SPEC"' -m '"$MODEL"' 2>&1 || true)
        # ... process and log output
    ' _ {}
else
    # Original sequential code
fi
```

**Rationale:** Dramatically speeds up tasks with independent turns, better resource utilization.

### 6.4 Add Retry Logic
**Location:** opencode execution

**Issue:** Transient failures cause entire run to fail.

**Recommendation:**
```bash
# Add retry logic with exponential backoff
MAX_RETRIES=3
RETRY_DELAY=5

for attempt in $(seq 1 "$MAX_RETRIES"); do
    if timeout "$TIMEOUT" opencode run "$INSTRUCTION" --file "$SPEC" -m "$MODEL" 2>&1 | tee "$TMPOUT"; then
        break  # Success
    else
        if [[ "$attempt" -lt "$MAX_RETRIES" ]]; then
            echo "Turn $i failed (attempt $attempt/$MAX_RETRIES), retrying in ${RETRY_DELAY}s..."
            sleep "$RETRY_DELAY"
            RETRY_DELAY=$((RETRY_DELAY * 2))  # Exponential backoff
        else
            echo "Turn $i failed after $MAX_RETRIES attempts"
            # Decide whether to continue or exit
        fi
    fi
done
```

**Rationale:** Improves robustness against network issues, API rate limits, temporary failures.

### 6.5 Add Rate Limiting
**Location:** Between turns

**Issue:** Can overwhelm APIs or systems.

**Recommendation:**
```bash
# Add --rate-limit flag
RATE_LIMIT=""
if [[ "${1:-}" == "--rate-limit" ]]; then
    shift
    RATE_LIMIT="${1:-2}"  # Default: 2 seconds between requests
    shift
fi

# Between turns, add delay
if [[ -n "$RATE_LIMIT" ]]; then
    sleep "$RATE_LIMIT"
fi
```

**Rationale:** Prevents API throttling, plays nice with shared resources.

### 6.6 Add Turn Time Limits
**Location:** Per-turn execution

**Issue:** No way to limit individual turn duration while allowing different overall timeouts.

**Recommendation:**
```bash
# Add --turn-timeout flag (separate from global TIMEOUT)
TURN_TIMEOUT=""
if [[ "${1:-}" == "--turn-timeout" ]]; then
    shift
    TURN_TIMEOUT="${1:-$TIMEOUT}"
    shift
fi

# Use per-turn timeout in loop
timeout "${TURN_TIMEOUT:-$TIMEOUT}" opencode run "$INSTRUCTION" --file "$SPEC" -m "$MODEL" 2>&1 | tee "$TMPOUT"
```

**Rationale:** Prevents individual turns from hogging resources, allows different strategies.

### 6.7 Add Output Filtering
**Location:** Output processing

**Issue:** Logs contain lots of noise, hard to find signal.

**Recommendation:**
```bash
# Add --filter flag
FILTER=""
if [[ "${1:-}" == "--filter" ]]; then
    shift
    FILTER="$1"
    shift
fi

# Apply filter to output
if [[ -n "$FILTER" ]]; then
    OUTPUT=$(grep -E "$FILTER" <<< "$OUTPUT" || echo "")
fi
```

**Rationale:** Reduces log noise, focuses on relevant information.

### 6.8 Add Turn Validation
**Location:** After each turn

**Issue:** No validation that turns are producing useful output.

**Recommendation:**
```bash
# Add --validate flag with pattern
VALIDATE_PATTERN=""
if [[ "${1:-}" == "--validate" ]]; then
    shift
    VALIDATE_PATTERN="$1"
    shift
fi

# After each turn, validate output
if [[ -n "$VALIDATE_PATTERN" ]]; then
    if ! grep -qE "$VALIDATE_PATTERN" <<< "$OUTPUT"; then
        echo "Turn $i validation failed: pattern not found: $VALIDATE_PATTERN" >&2
        # Option to retry or continue
    fi
fi
```

**Rationale:** Ensures turns meet quality standards, catches issues early.

### 6.9 Add Turn Dependencies
**Location**: Turn scheduling

**Issue**: Cannot specify which turns depend on others.

**Recommendation:**
```bash
# Add --dependencies flag with dependency file
DEPS_FILE=""
if [[ "${1:-}" == "--dependencies" ]]; then
    shift
    DEPS_FILE="$1"
    shift
fi

# Parse dependencies and topologically sort turns
if [[ -n "$DEPS_FILE" ]]; then
    # Simple format: turn:dep1,dep2
    # Use tsort or custom implementation
    declare -A TURNS_WITH_DEPS
    while IFS=: read -r turn deps; do
        TURNS_WITH_DEPS["$turn"]="$deps"
    done < "$DEPS_FILE"
    
    # Execute in dependency order
    for turn in $(tsort < "$DEPS_FILE"); do
        # ... execute turn
    done
fi
```

**Rationale:** Enables complex workflows with prerequisites, better organization.

### 6.10 Add Template System
**Location**: Create new file

**Issue**: Every new task requires writing spec from scratch.

**Recommendation:**
```bash
# Add template command to main dispatcher
template)
    shift
    TEMPLATE_NAME="${1:-basic}"
    shift
    
    case "$TEMPLATE_NAME" in
        basic)
            cat << 'EOF'
# TASK
[Describe your task here]

# RULES
- Do ONE bounded increment only.
- Minimal diff. No repo-wide churn.
- If you change code: run all VERIFIERS before finishing.
- Append one short line to `progress.log` (timestamp, what changed, what's next).
- If you are done and verifiers pass, print exactly: <promise>COMPLETE</promise>

# VERIFIERS
[Add your verifiers here]
EOF
            ;;
        research)
            cat << 'EOF'
# TASK
[Describe research topic]

# SCOPE
- Define scope
- Define exclusions

# SEED LIST
- Topic 1
- Topic 2

# RULES
- Remove items from SEED LIST as completed
- Save findings to docs/research/[topic].md
- If done, print exactly: <promise>COMPLETE</promise>

# VERIFIERS
- [[ -d "docs/research" ]] && echo "✓ Research directory exists"
EOF
            ;;
        *)
            echo "Unknown template: $TEMPLATE_NAME"
            echo "Available templates: basic, research"
            exit 1
            ;;
    esac
    ;;
```

**Rationale:** Reduces boilerplate, provides best practice starting points, improves consistency.

---

## Implementation Priority

### Phase 1 (Immediate - 1-2 days)
- 1.1 Enhance Model Name Validation
- 1.2 Add Temp File Cleanup on Interrupt
- 1.3 Validate Spec File Size and Type
- 2.2 Consolidate ANSI Stripping Functions
- 2.4 Add Logging Configuration at Startup
- 3.2 Optimize Promise Token Search
- 4.3 Add Help Command

### Phase 2 (Short-term - 1 week)
- 2.1 Extract Constants to Top of Script
- 2.3 Improve Error Messages with Context
- 2.5 Add Shellcheck Compliance
- 4.1 Add Verbose/Quiet Modes
- 4.2 Add Summary Statistics
- 5.1 Add Comprehensive README
- 5.2 Add Unit Tests

### Phase 3 (Medium-term - 2-3 weeks)
- 4.4 Add Config File Support
- 5.3 Add Integration Tests
- 5.4 Add Example Specs
- 6.1 Add Resume Capability
- 6.2 Add Turn Skipping
- 6.5 Add Rate Limiting
- 6.10 Add Template System

### Phase 4 (Long-term - 1-2 months)
- 3.3 Add Progress Reporting Option
- 6.3 Add Parallel Execution Option
- 6.4 Add Retry Logic
- 6.6 Add Turn Time Limits
- 6.7 Add Output Filtering
- 6.8 Add Turn Validation
- 6.9 Add Turn Dependencies

---

## Testing Strategy

1. **Unit Tests**: Test individual functions (strip_ansi, json_escape, validation)
2. **Integration Tests**: Test complete workflows (basic task, research task)
3. **Manual Testing**: Test new features with real opencode runs
4. **Performance Testing**: Measure impact of optimizations
5. **Security Testing**: Test edge cases and attack vectors

---

## Conclusion

This document provides a comprehensive roadmap for improving ralph.sh from a minimal tool to a production-ready, robust, user-friendly loop harness. The recommendations are prioritized by impact and feasibility, allowing for incremental implementation while maintaining the tool's simplicity and core philosophy.

Key themes:
- **Security first**: Validate all inputs, handle errors gracefully
- **User experience**: Make it easy to use, debug, and understand
- **Code quality**: Use best practices, add tests, improve maintainability
- **Features**: Add capabilities that provide real value without complexity

Implement these changes in phases, testing thoroughly at each stage, and the result will be a significantly improved tool that serves users better while remaining true to Ralph's minimalist ethos.
