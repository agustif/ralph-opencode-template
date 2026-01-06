# ralph-opencode-template

Automation loop for [ralph](https://github.com/agustif/ralph) + [opencode](https://github.com/anomalyco/opencode).

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/agustif/ralph-opencode-template/main/install.sh | bash
```

## Usage

```bash
ralph 50 prompt.md    # Run 50 turns
ralph --test         # Test mode
make test            # Run verifiers
make clean           # Clean logs
```

## Files

- `prompt.md` - Task instructions (edit this)
- `ralph.sh` - Main script  
- `Makefile` - Utilities
- `install.sh` - Installer

Edit `prompt.md` with your task. The script runs opencode in a loop until it sees `<promise>COMPLETE</promise>`.

## Prompt.md Structure

```markdown
# TASK
What you want to accomplish.

# SCOPE  
Boundaries and constraints.

# RULES
- Must pass all verifiers
- Keep changes minimal
- Follow project conventions

# VERIFIERS
- [[ -f "file.txt" ]]
- command
- grep -q "pattern" file
```

The loop stops when all verifiers pass and the agent outputs `<promise>COMPLETE</promise>`.

## License

MIT
