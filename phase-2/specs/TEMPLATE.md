# Spec NN — <domain name>

> Copy this file to `spec-NN-<slug>.md`, fill every section, open a PR.
> The `spec-gate` workflow scores SQL generated from it; mean precision must
> reach 0.85 to merge. Aim for Spec-B depth (~480 words) — Phase 1 showed that
> is the cost/quality sweet spot. Sections below are the Phase 1 checklist
> (see ../../phase-1/03-analysis/ANALYSIS.md §5).

## Domain
<!-- What the schema represents, in 2-3 sentences. -->

## Scope (tables)
<!-- Explicit table list with key columns. The gate penalizes hallucinated tables. -->

## Tech stack
<!-- DB version, PK strategy, FK naming, timestamp/soft-delete columns. -->

## Conventions
<!-- snake_case, status approach (CHECK vs ENUM), enumerated value sets, money type. -->

## Integrity rules
<!-- PK/FK, ON DELETE policy per relation, UNIQUE, CHECK, soft-delete pattern. -->

## Safe-change rules
<!-- Nullable/defaulted new columns, no renames, index every FK + hot paths. -->

## Out of scope
<!-- What NOT to generate — this is what stops invented features. -->

## Deliverable
<!-- Exact output format: single .sql, constraints + indexes + COMMENT ON, no prose. -->
