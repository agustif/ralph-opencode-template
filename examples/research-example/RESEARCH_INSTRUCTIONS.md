# Shitty Deep Research (Local) — AI Coding Agents + Agent SDKs + Evals

## Mission
Research the AI coding-agent ecosystem and distill into:
- competitor matrix
- per-incumbent dossiers
- cross-cutting patterns
- a derived plan for *our* platform (CLI/TUI/SDK)

## HARD CONSTRAINTS
- Write **only** under: `docs/research/**` and `progress.log`.
- Do not change code outside that scope.
- Every factual claim must have a source URL in the same section.
- Keep excerpts <= 25 words each (quote sparingly).
- Prefer primary sources (official docs, GitHub repos, papers).

## Outputs (must exist at end)
- `docs/research/COMPETITOR_MATRIX.md`
- `docs/research/PATTERNS.md`
- `docs/research/OUR_PLAN.md`
- `docs/research/SOURCES.md`
- `docs/research/INCUMBENTS/<name>.md` (one per incumbent)
- `docs/research/progress.log` (append-only)

## Scope (true blast radius)
Cover these categories (do not ignore any):
1) Terminal/IDE coding agents (UX + operational features)
2) Vendor agent SDKs (OpenAI/Anthropic/etc.) + tool-calling surfaces
3) Orchestration frameworks (LangGraph-like, typed agent libs, etc.)
4) SWE benchmarks/environments (SWE-bench variants, SWE-Gym, Terminal benches)
5) Security/sandboxing + permissions + policy models
6) Observability (traces, replay, cost/latency budgeting)

## Incumbent seed list (expand as needed)
Start with these, then expand to reach >= 12 incumbents total:
- Claude Code (public docs only; enumerate features/APIs/commands)
- OpenAI Codex CLI
- OpenCode
- OpenHands (OpenDevin)
- SWE-agent (+ paper)
- Continue
- Aider
- Cursor (agent modes)
- Prime Intellect: verifiers/environments hub / prime-rl (env abstraction)
- Benchmarks: SWE-bench (Verified/Lite/Live), SWE-Gym, Terminal-Bench, EnvBench

## Work batching
Each run should process 2–4 incumbents max:
- add matrix rows
- create/update 2–4 incumbent dossiers
- add patterns discovered
- refine OUR_PLAN only when patterns justify it

## Dossier schema (must follow exactly)
For each `docs/research/INCUMBENTS/<name>.md`:
- What it is (1 sentence)
- Primary UX (CLI/TUI/IDE/Web)
- Execution model (local/remote/sandbox)
- Tooling surface (filesystem/shell/web/tools)
- Context strategy (repo-map/indexing/RAG/etc.)
- Verification gates (tests/CI/evaluator)
- Extensibility model (plugins/commands/config)
- Ops model (headless/background/CI integrations)
- Notable design choices
- Failure modes / critiques
- Sources (URLs + short excerpts)

## Completion condition
When:
- matrix has >= 12 incumbents
- patterns has >= 15 patterns
- OUR_PLAN has 8–12 milestones with acceptance checks
- all outputs exist and are non-empty

Then print exactly:
<promise>COMPLETE</promise>
