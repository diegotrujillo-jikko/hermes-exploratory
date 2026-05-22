# hermes-exploratory

Validating **context engineering** with **Hermes** (LLM orchestrator,
[NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent)) and
**W&B** (run observability) before applying the methodology to JikkoOps.

Two phases, one per folder:

## [Phase 1 — exploratory](./phase-1/README.md) (`phase-1/`)

Manual sweep of **spec depth × model** on a throwaway domain (order management)
to find the SQL-quality sweet spot. Complete; left as-is.

- Hypothesis, method, rounds, results → [`phase-1/README.md`](./phase-1/README.md)
- Rationale → [`phase-1/METHODOLOGY.md`](./phase-1/METHODOLOGY.md)
- Final recommendation → [`phase-1/03-analysis/ANALYSIS.md`](./phase-1/03-analysis/ANALYSIS.md)
- **Finding:** spec depth beats model tier; a balanced ~480-word spec ("Spec B")
  + Sonnet is the cost/quality default.

## [Phase 2 — automated gate](./phase-2/README.md) (`phase-2/`)

Turns the Phase 1 finding into a **GitHub Actions quality gate**. A designer
pushes a spec; CI generates SQL from it with two models, an LLM judge scores
each against the same rubric, the PR gets a score comment, and merge is blocked
until mean precision (rubric total / 100) ≥ 0.85.

- Usage, secrets, branch protection → [`phase-2/README.md`](./phase-2/README.md)
- 7-step image flow → file map → [`phase-2/ARCHITECTURE.md`](./phase-2/ARCHITECTURE.md)
- Workflow → [`.github/workflows/spec-gate.yml`](./.github/workflows/spec-gate.yml)

## Layout

```
phase-1/        # exploratory experiment (01-specs … 04-skills, scripts, analysis)
phase-2/        # automated CI spec-quality gate (specs, scripts, config)
.github/        # spec-gate.yml — runs only from repo root
.env.example    # shared API keys template (ANTHROPIC_API_KEY, WANDB_API_KEY)
```

## Setup

Copy the shared secrets template once at the repo root:

```bash
cp .env.example .env   # fill ANTHROPIC_API_KEY (+ WANDB_API_KEY optional)
```

Then follow the per-phase README for that phase's tooling.
