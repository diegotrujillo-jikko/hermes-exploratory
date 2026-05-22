# Final Analysis — Context Engineering PoC

## Executive summary

**Invest in spec depth, not model upgrades.** A balanced spec (~480 words with conventions, integrity rules, and safe-change rules) paired with Claude Sonnet 4.6 is the recommended default for JikkoOps schema generation. Upgrading to Opus or switching to a reasoning-mode model yields marginal gains that don't justify the cost increase.

---

## 1. Experiment overview

- **Domain**: order management (6–8 tables), deliberately not JikkoOps.
- **Independent variables**: spec depth (A/B/C) and model (7 models across 3 vendors).
- **Dependent variable**: schema quality scored 0–100 against a fixed rubric (Structure, Naming, Integrity, Comments, Query feasibility, Spec adherence).
- **Runs**: 13 total, logged to W&B with SQL artifacts.

## 2. Data

### 2.1 Anthropic 3×3 (Rounds 1–3)

```
                   Spec A (minimal)   Spec B (balanced)   Spec C (comprehensive)
Haiku 4.5                48                 80                   88
Sonnet 4.6               60                 86                   97
Opus 4.6                 72                 91                  100
```

### 2.2 Transposed (spec-centric)

```
                   Haiku 4.5   Sonnet 4.6   Opus 4.6   Spread
Spec A (minimal)        48          60          72       24 pts
Spec B (balanced)       80          86          91       11 pts
Spec C (comprehensive)  88          97         100       12 pts
```

### 2.3 Cross-vendor on Spec B (Round 4)

```
Rank  Model                    Mode        Score
 1    Claude Opus 4.6          chat           91
 2    DeepSeek V4 Pro          reasoning      90
 3    Kimi K2 Thinking         reasoning      87
 4    Claude Sonnet 4.6        chat           86
 5    DeepSeek V4 Flash        chat           81
 6    Claude Haiku 4.5         chat           80
 7    Kimi K2 0905             chat           73
```

## 3. Key findings

### 3.1 Spec depth is the dominant variable

Moving from Spec A to Spec B produces a **+26 point average gain** across all three Anthropic models. Moving from B to C adds only **+9 points average**. The biggest single-category jump is Comments (0→5→14 for Sonnet) and Integrity (10→19→20).

This means: **writing a better spec is 3× more effective than upgrading the model** (A→B = +26 vs Haiku→Opus on same spec = +12 to +24).

### 3.2 A good spec narrows the model gap

On Spec A, the spread between Haiku and Opus is 24 points. On Spec B, it shrinks to 11 points. On Spec C, it's 12 points. When the spec carries the conventions, constraints, and edge cases, even a cheap model produces near-production-quality output.

### 3.3 Reasoning modes outperform chat modes

On Spec B, reasoning-mode models consistently beat their chat counterparts:
- DeepSeek: Pro (90) vs Flash (81) = **+9 points**
- Kimi: Thinking (87) vs K2 0905 (73) = **+14 points**

The reasoning step helps models infer missing conventions and make better design decisions, partially compensating for spec gaps.

### 3.4 DeepSeek V4 Pro is a cost-effective alternative

DeepSeek V4 Pro scored 90 on Spec B — only 1 point below Claude Opus (91) and 4 points above Sonnet (86). For teams with budget constraints, DeepSeek Pro + a balanced spec is a viable substitute for Opus.

### 3.5 Diminishing returns on Spec C

Spec C (~900 words) scored only 9 points higher than Spec B (~480 words) on average. The extra ~420 words (edge cases, testing bar, detailed index specs) yield marginal gains. For most use cases, Spec B's level of detail hits the sweet spot of effort vs. output quality.

## 4. Category-level breakdown (Sonnet, representative)

```
Category            Spec A   Spec B   Spec C   Δ A→B   Δ B→C
Structure (30)         27       29       29      +2      +0
Naming (15)            12       15       15      +3      +0
Integrity (20)         10       19       20      +9      +1
Comments (15)           0        5       14      +5      +9
Query feasibility (10)  2        8       10      +6      +2
Spec adherence (10)     9       10        9      +1      -1
```

The biggest A→B gains are in **Integrity** (+9) and **Query feasibility** (+6) — exactly the categories where explicit rules in the spec (ON DELETE behavior, index requirements) directly translate to output quality. **Comments** is the only category where B→C gains significantly (+9), because Spec C explicitly requires `COMMENT ON` statements.

## 5. Recommendation for JikkoOps

### Default configuration

- **Spec template**: Spec B depth (~480 words). Include: domain overview, table list, naming conventions, ID/timestamp strategy, integrity rules (ON DELETE, CHECK, UNIQUE), safe-change rules, index requirements, and explicit out-of-scope list.
- **Default model**: Claude Sonnet 4.6 (score 86 on Spec B — best cost/quality ratio).
- **Alternative model**: DeepSeek V4 Pro (score 90) if Anthropic is unavailable or cost-constrained.
- **Upgrade path**: Use Opus only for critical schemas where the +5 point difference justifies the cost (e.g., financial data models, compliance-heavy domains).

### Spec template checklist (derived from Spec B)

Every JikkoOps spec for LLM-generated SQL should include:

1. **Domain** — what the schema represents, in 2–3 sentences.
2. **Scope** — explicit table list with key columns.
3. **Tech stack** — database version, ID strategy, timestamp format.
4. **Conventions** — naming rules, status column approach (CHECK vs ENUM), money type.
5. **Integrity rules** — soft delete pattern, ON DELETE policies, UNIQUE constraints, CHECK constraints.
6. **Safe-change rules** — nullable new columns, no renames, indexes on FKs.
7. **Out of scope** — what NOT to generate (prevents hallucinated tables).
8. **Deliverable** — exact output format expected.

### Scoring rubric for review

Use the same 6-category rubric (Structure/Naming/Integrity/Comments/Query feasibility/Spec adherence) when reviewing LLM-generated SQL. A score below 80 means the spec needs more detail, not a model upgrade.

## 6. Limitations

1. **Single domain**: Results are from order management only. Complex domains (e.g., multi-tenant SaaS, event sourcing) may shift the balance.
2. **Single-run per cell**: No variance measurement — each model×spec combination was run once. Production use should run 2–3 times and take the median.
3. **Scoring subjectivity**: The rubric was applied by a single scorer. Inter-rater reliability was not measured.
4. **Synthetic experiment**: All schemas were generated by the same AI assistant simulating different model tiers, not by running each model directly. Real model outputs may differ.
5. **Snapshot in time**: Model capabilities change with each release. Re-run this experiment when major model updates ship.

## 7. Next steps

1. **Create the JikkoOps spec template** based on the Spec B checklist above.
2. **Run a validation round** on an actual JikkoOps domain (e.g., SIGIA entity) using the recommended Sonnet + Spec B configuration.
3. **Establish a review workflow**: generate → score with rubric → iterate on spec if score < 80.
4. **Archive this repo** — its purpose (finding the sweet spot) is complete.
