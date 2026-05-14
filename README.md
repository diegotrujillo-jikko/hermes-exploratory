# hermes-exploratory

Bounded experiment to validate **context engineering** with **Hermes** (LLM orchestrator) and **wan.db** (W&B observability) before applying the methodology to JikkoOps.

## Hypothesis

Spec depth + model choice produce measurable variance in LLM-generated database schemas. Find the sweet spot.

## Method

1. Pick a small domain (e.g. order management, auth) — **not JikkoOps**.
2. Write 3 specs for the same problem in `01-specs/`:
   - `spec_a.md` — minimal (~150 words): overview + tech stack.
   - `spec_b.md` — balanced (~480 words): + conventions, integrity, safe-change rules.
   - `spec_c.md` — comprehensive (~900 words): + examples, edge cases, testing bar.
3. Run via Hermes, save SQL to `02-outputs/<round>_<model>_<spec>.sql`:
   - Round 1: Sonnet × {A, B, C}
   - Round 2: Opus × {A, B, C}
   - Round 3: Spec B × {Sonnet, Opus, Haiku}
4. Score each output with the rubric below, log to wan.db, write findings to `03-analysis/`.

## Scoring rubric (0–100)

| Category | Max | What to check |
|---|---|---|
| Structure | 30 | Required tables, FK relationships, no hallucinated tables |
| Naming | 15 | snake_case, `id`/`{table}_id`, `created_at`/`updated_at`/`deleted_at` |
| Integrity | 20 | PK/FK, NOT NULL, UNIQUE, soft delete, CASCADE/RESTRICT |
| Comments | 15 | Tables and non-obvious decisions documented |
| Query feasibility | 10 | Key queries supported, indexes on FK + hot paths |
| Spec adherence | 10 | Followed spec, no invented features |

## Layout

```
01-specs/      # spec_a.md, spec_b.md, spec_c.md
02-outputs/    # <round>_<model>_<spec>.sql
03-analysis/   # metrics.json, comparison.md, report.md
```

## Done when

- 7 SQL outputs scored and logged.
- Comparison matrix + recommendation (which spec depth, which model) for JikkoOps.
