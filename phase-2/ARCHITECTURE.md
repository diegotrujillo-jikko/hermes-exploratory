# Phase 2 architecture — image → code map

The source image describes a 7-step automated pipeline. This file pins each step
to the exact file/line that implements it, so the repo stays in sync with the image.

```
┌─ designer ─┐     ┌──────── GitHub Actions: spec-gate ────────┐
│ edit spec  │ PR  │                                            │
│ specs/     │────▶│ 1.detect → 2.generate → 3.judge → 4.log    │──┐
│ spec-NN.md │     │            (2 models)   (rubric)  (W&B)     │  │
└────────────┘     └────────────────────────────────────────────┘  │
                                                                     ▼
        merge ◀── 7.unblock ◀── 6.gate (≥0.85?) ◀── 5.comment scores on PR
        & backend starts          │ no
                                   └─▶ PR blocked, designer revises spec
```

## Step-by-step

| # | Image (ES) | Meaning | Implemented by |
|---|---|---|---|
| 1 | Diseñador hace push de spec nuevo → `specs/spec-06-reportes.md` | new spec in a PR | `phase-2/specs/spec-06-reportes.md` (+ `TEMPLATE.md`) |
| 2 | GitHub Actions detecta el cambio | trigger on spec change | `.github/workflows/spec-gate.yml` → `on.pull_request.paths: phase-2/specs/**.md` + "List changed specs" step |
| 3 | Hermes evalúa el spec con 2 modelos | generate SQL with two models, then judge | `scripts/evaluate_spec.py` → `generate_sql()` (per generator in `config/models.yml`) + `judge_sql()` |
| 4 | W&B registra los runs con métricas | log scores + SQL artifact | `scripts/evaluate_spec.py` → `log_to_wandb()` (when `WANDB_API_KEY` set) |
| 5 | El PR recibe comentario con scores | post score table | `scripts/comment_pr.py` → workflow `gh pr comment --body-file comment.md` |
| 6 | precisión < 0.85 → PR bloqueado | enforce threshold | `scripts/gate.py` (exit 1) + `rubric.py` `PRECISION_THRESHOLD = 0.85`; effective once `spec-gate / evaluate` is a **required** check |
| 7 | supera el gate → listo para merge, backend arranca | green check unblocks merge | `gate.py` exit 0 → required check passes |

## Design choices (sync notes)

- **Image models vs. repo models.** The image names `gpt-5.5` and `gpt-5.3-codex`;
  this scaffold keeps **Phase 1 models** (single `ANTHROPIC_API_KEY`). The mapping
  lives in `config/models.yml` — `generators[0]` ↔ `gpt-5.5`, `generators[1]` ↔
  `gpt-5.3-codex`. Swap ids there to track the image literally.
- **"Evaluate the spec" = score SQL the spec produces.** Phase 1's rubric scores
  SQL, not prose. Phase 2 keeps that meaning: it generates SQL from the spec and
  judges *that*. A weak spec yields weak SQL → low precision → blocked. Same signal
  the image intends, with a rubric that stays valid.
- **precision = rubric_total / 100.** Direct normalization of Phase 1's 0–100 score.
  The gate compares the **mean across generator models** to 0.85.
- **Two evaluators, one judge.** The image runs two generator models; one judge
  scores both for a consistent yardstick. Judge id is configurable.

## What is NOT here (future scaling)

- Per-category gating (e.g. integrity must be ≥ 18) — currently only the total gates.
- Variance handling: Phase 1 limitation #2 (single run per cell) carries over; add
  N-run median if flakiness appears.
- Auto-creating the backend scaffold on pass (step 7 "backend arranca") — left as a
  downstream workflow `needs: evaluate`.
