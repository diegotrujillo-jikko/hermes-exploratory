#!/usr/bin/env python3
"""
Phase 2 — quality gate (image step 6: "Si precisión < 0.85 -> PR bloqueado").

Reads every <slug>__<model>.json record produced by evaluate_spec.py for one
spec, computes the mean precision across generator models, and exits non-zero
when it falls below PRECISION_THRESHOLD. The non-zero exit fails the required
status check, which is what blocks the PR merge.

Usage:
    python gate.py --spec spec-06-reportes --out-dir .eval-out
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from rubric import PRECISION_THRESHOLD  # noqa: E402

EXIT_PASS = 0
EXIT_BLOCKED = 1
EXIT_ERROR = 2


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--spec", required=True, help="spec slug, e.g. spec-06-reportes")
    parser.add_argument("--out-dir", default=".eval-out")
    return parser.parse_args()


def load_records(out_dir: Path, spec_slug: str) -> list[dict]:
    """Load all score records for a spec. Fail fast if none were produced."""
    records = [json.loads(p.read_text(encoding="utf-8"))
               for p in sorted(out_dir.glob(f"{spec_slug}__*.json"))]
    if not records:
        raise FileNotFoundError(f"no eval records for {spec_slug} in {out_dir}")
    return records


def mean_precision(records: list[dict]) -> float:
    return round(sum(r["precision"] for r in records) / len(records), 4)


def main() -> int:
    args = parse_args()
    out_dir = Path(args.out_dir)
    try:
        records = load_records(out_dir, args.spec)
    except (FileNotFoundError, json.JSONDecodeError) as exc:
        sys.stderr.write(f"gate error: {exc}\n")
        return EXIT_ERROR

    precision = mean_precision(records)
    per_model = ", ".join(f"{r['model']}={r['precision']:.2f}" for r in records)
    print(f"spec={args.spec} mean_precision={precision:.4f} "
          f"threshold={PRECISION_THRESHOLD} ({per_model})")

    if precision < PRECISION_THRESHOLD:
        print(f"BLOCKED: {precision:.2f} < {PRECISION_THRESHOLD} — improve the spec.")
        return EXIT_BLOCKED
    print(f"PASS: {precision:.2f} >= {PRECISION_THRESHOLD} — PR may merge.")
    return EXIT_PASS


if __name__ == "__main__":
    sys.exit(main())
