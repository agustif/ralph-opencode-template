# TASK
[Describe the research topic or question to investigate]

# SCOPE
- Define what topics/areas to research
- Define what to exclude from the research

# SEED LIST
[Initial topics/questions to start research with:
- Topic 1
- Topic 2
- Topic 3
...]

# RULES
- Remove items from SEED LIST as they're completed
- Add new items discovered during research
- Save findings to docs/research/[topic].md
- Minimal output - focus on key insights
- If no specific task, explore next seed item
- Do ONE bounded increment only
- If you change files: run all VERIFIERS before finishing
- If done, print exactly: <promise>COMPLETE</promise>

# VERIFIERS
- [[ -d "docs/research" ]] && echo "✓ Research directory exists"
- [[ $(find docs/research -name "*.md" 2>/dev/null | wc -l) -gt 0 ]] && echo "✓ Research files created" || echo "⚠ No research files found"
- ./ralph.sh run --test 1 RESEARCH_INSTRUCTIONS.md 2>/dev/null && echo "✓ Script runs"
- bash -n ralph.sh && echo "✓ Syntax valid"

<promise>COMPLETE</promise>
