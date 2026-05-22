# Phase 2 — Automated spec quality gate

Phase 1 (repo root: `01-specs/` … `04-skills/`) was a **manual, exploratory**
experiment: find which spec depth × model produces the best SQL, scored by hand.
That exercise is **done and stays untouched**.

Phase 2 **operationalizes the finding as CI**. A designer pushes a spec; GitHub
Actions generates SQL from it with two models, an LLM judge scores each against
the same 6-category rubric, the PR gets a score comment, and the merge is blocked
until mean `precision` (= rubric total / 100) reaches **0.85**.

This is the flow in the source image — see [ARCHITECTURE.md](./ARCHITECTURE.md)
for the step-by-step mapping.

## Layout

```
phase-2/
  specs/
    TEMPLATE.md            # copy this to author a new spec
    spec-06-reportes.md    # sample spec (the image's example)
  scripts/
    rubric.py              # shared 6-cat rubric + PRECISION_THRESHOLD (reused from Phase 1)
    evaluate_spec.py       # generate SQL (generator) -> score (judge) -> JSON + W&B  [steps 3,4]
    comment_pr.py          # render score table as PR comment markdown               [step 5]
    gate.py                # mean precision >= 0.85 ? exit 0 : exit 1                 [step 6]
  config/
    models.yml             # generator + judge model ids, token limits
  requirements.txt         # anthropic, wandb, pyyaml, python-dotenv
  .eval-out/               # generated SQL + scores (git-ignored, CI artifact)
```

The workflow itself lives at repo root `.github/workflows/spec-gate.yml` —
GitHub only runs workflows from that path, so it cannot live inside `phase-2/`.
Everything it calls does.

## How it runs

1. Author a spec: `cp specs/TEMPLATE.md specs/spec-07-<slug>.md`, fill it in.
2. Open a PR. The `paths:` trigger fires only when `phase-2/specs/**.md` changes.
3. CI runs each generator in `config/models.yml`, judges the SQL, posts a comment.
4. `gate.py` fails the check if mean precision < 0.85 → PR blocked.
5. Improve the spec, push again; re-runs until it passes → mergeable, backend starts.

## Required CI secrets

| Secret | Used for | Required |
|---|---|---|
| `ANTHROPIC_API_KEY` | generator + judge model calls | yes |
| `WANDB_API_KEY` | run/metric logging (step 4) | optional — skipped if absent |

`GITHUB_TOKEN` is provided automatically; the workflow grants it `pull-requests: write`.

## Making the gate actually block (step 6)

The failing check blocks merge **only** if it is a required status check:

> Repo → Settings → Branches → branch protection rule for `main` →
> *Require status checks to pass* → add **`spec-gate / evaluate`**.

Without this, the red check is advisory and a maintainer can still merge.

## Run locally

```bash
cd phase-2
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
export ANTHROPIC_API_KEY=...        # WANDB_API_KEY optional

python scripts/evaluate_spec.py --spec specs/spec-06-reportes.md \
    --model claude-sonnet-4-6 --judge claude-opus-4-7 --no-wandb
python scripts/evaluate_spec.py --spec specs/spec-06-reportes.md \
    --model claude-opus-4-7 --judge claude-opus-4-7 --no-wandb
python scripts/comment_pr.py --spec spec-06-reportes
python scripts/gate.py --spec spec-06-reportes   # echoes PASS/BLOCKED, sets exit code
```

## Relationship to Phase 1

| | Phase 1 (root) | Phase 2 (here) |
|---|---|---|
| Goal | find the sweet spot | enforce it on every spec |
| Trigger | human runs CLI | PR push |
| Scoring | manual rubric | LLM-as-judge, same rubric |
| Output | analysis + recommendation | pass/block gate + PR comment |
| Models | swept A/B/C × 7 models | fixed pair from `config/models.yml` |

Phase 2 imports nothing from Phase 1's code; it **reuses the rubric definition**
(re-declared in `scripts/rubric.py`) so the two phases score identically.
