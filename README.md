# Ralph Loop + Shitty Deep Research (OpenCode) — Template Repo

A tiny, reusable **while-loop harness** for running long-lived agent iterations with **OpenCode** (`opencode run`),
plus a ready-to-use **research spec** that generates a competitor matrix + dossiers + patterns + a derived plan.

This repo is intentionally minimal: you edit a single Markdown spec (`prompt.md` or `RESEARCH_INSTRUCTIONS.md`) and rerun the loop.

## Prereqs

- OpenCode CLI installed and configured (`opencode` in PATH)
- A model/provider configured in OpenCode
- Basic tools available locally: `git`, `curl` (optional but useful for research)

## Quickstart: run Ralph on any task

1. Edit `prompt.md` with your task, rules, and verifiers.
2. Run:

```bash
chmod +x ralph.sh
./ralph.sh 50 prompt.md
```

The loop stops early when the agent prints:

```
<promise>COMPLETE</promise>
```

Logs go to `.ralph.log` (gitignored).

## Quickstart: “shitty deep research” mode

1. Edit `RESEARCH_INSTRUCTIONS.md` (seed list + scope).
2. Run:

```bash
./ralph.sh 30 RESEARCH_INSTRUCTIONS.md
```

Outputs land in `docs/research/`.

## How it works

- `ralph.sh` is a minimal bounded loop.
- The spec file (`prompt.md` / `RESEARCH_INSTRUCTIONS.md`) is the *authoritative contract*.
- The only universal stop condition is the `<promise>COMPLETE</promise>` token.

## Publishing as a GitHub template

- Push this repo to GitHub.
- In GitHub: **Settings → Template repository → Enable**.
- Users can click **Use this template**.

## License

MIT (see `LICENSE`).
