#!/usr/bin/env python3
"""
Shared rubric definition for Phase 2 (CI spec-quality gate).

Mirrors the 6-category, 0-100 rubric from Phase 1 (see ../../README.md and
scripts/log_run.py) so both phases score SQL the same way. Phase 2 adds the
gate threshold: a spec "passes" when the mean precision across evaluator
models is >= PRECISION_THRESHOLD.
"""
from __future__ import annotations

from typing import Final

# (category, max_points) — identical to Phase 1 scripts/log_run.py
SCORE_CATEGORIES: Final[tuple[tuple[str, int], ...]] = (
    ("structure", 30),
    ("naming", 15),
    ("integrity", 20),
    ("comments", 15),
    ("query_feasibility", 10),
    ("spec_adherence", 10),
)

MAX_TOTAL: Final[int] = sum(maximum for _, maximum in SCORE_CATEGORIES)  # 100

# Image step 6: "Si precisión < 0.85 -> PR bloqueado".
PRECISION_THRESHOLD: Final[float] = 0.85


def validate_scores(scores: dict[str, int]) -> dict[str, int]:
    """Return a new dict with each category clamped to [0, max]; fail on missing keys.

    Immutable: never mutates the input.
    """
    validated: dict[str, int] = {}
    for category, maximum in SCORE_CATEGORIES:
        if category not in scores:
            raise ValueError(f"missing score category: {category}")
        raw = scores[category]
        if not isinstance(raw, (int, float)):
            raise ValueError(f"score for {category} must be numeric, got {type(raw)!r}")
        validated[category] = max(0, min(maximum, int(round(raw))))
    return validated


def total_of(scores: dict[str, int]) -> int:
    """Sum of validated category scores (0-100)."""
    validated = validate_scores(scores)
    return sum(validated.values())


def precision_of(scores: dict[str, int]) -> float:
    """Normalize the rubric total to [0, 1] for the gate. precision = total / 100."""
    return round(total_of(scores) / MAX_TOTAL, 4)
