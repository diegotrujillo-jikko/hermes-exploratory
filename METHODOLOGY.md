# Methodology

## Why this experiment exists

JikkoOps needs LLM-generated artifacts (schemas, migrations, code) that are consistent, reviewable, and aligned with internal conventions. The bottleneck is not the model — it is the **context** we hand the model: the spec.

Two failure modes are common:

1. **Spec too thin** → the model invents conventions, hallucinates tables, ignores integrity rules.
2. **Spec too thick** → the model gets buried in detail, ignores priorities, copies examples verbatim instead of generalising.

Somewhere in between is a sweet spot. This PoC finds it on a small, throwaway domain *before* applying the methodology to JikkoOps where the cost of getting it wrong is high.

## What we are measuring

The independent variable is **spec depth** (A: ~150 words, B: ~480 words, C: ~900 words). The dependent variable is **output quality** scored against a fixed rubric (Structure, Naming, Integrity, Comments, Query feasibility, Spec adherence).

The secondary variable is **model choice** (Sonnet, Opus, Haiku), measured in Round 3 against the depth that wins Rounds 1 and 2.

## Why a non-JikkoOps domain

Order management is small, well-understood, and free of internal context noise. If we ran this directly on JikkoOps the result would conflate two effects: the variance from spec depth and the variance from how well each model recalls JikkoOps patterns. Using a clean domain isolates the spec-depth signal.

## Tooling choice

CLI (Hermes) over a hand-rolled harness: the methodology must transfer to whoever runs JikkoOps schema generation next, and CLI is the lowest-friction transfer surface. Observability via wan.db keeps runs comparable across rounds.

## What we ship back to JikkoOps

A short recommendation: one spec template (the winning depth), one default model, and a scoring rubric that engineers can apply when reviewing future LLM-generated SQL. No framework, no abstractions — just the smallest reusable artifact that survives the move.
