#!/usr/bin/env python3
"""
Phase 2 — render the PR comment (image step 5: "El PR recibe un comentario
automático con los scores").

Reads the per-model score records for one spec and emits a Markdown summary to
stdout (and to --out-file). The workflow posts it with `gh pr comment`.

Usage:
    python comment_pr.py --spec spec-06-reportes --out-dir .eval-out --out-file comment.md
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from rubric import PRECISION_THRESHOLD, SCORE_CATEGORIES  # noqa: E402


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--spec", required=True)
    parser.add_argument("--out-dir", default=".eval-out")
    parser.add_argument("--out-file", default="comment.md")
    return parser.parse_args()


def load_records(out_dir: Path, spec_slug: str) -> list[dict]:
    records = [json.loads(p.read_text(encoding="utf-8"))
               for p in sorted(out_dir.glob(f"{spec_slug}__*.json"))]
    if not records:
        raise FileNotFoundError(f"no eval records for {spec_slug} in {out_dir}")
    return records


def render(spec_slug: str, records: list[dict]) -> str:
    """Build the Markdown comment: per-category table + gate verdict."""
    categories = [name for name, _ in SCORE_CATEGORIES]
    header = "| model | " + " | ".join(categories) + " | total | precision |"
    divider = "|" + "---|" * (len(categories) + 3)
    rows = []
    for r in records:
        scores = r["scores"]
        cells = " | ".join(str(scores[c]) for c in categories)
        rows.append(f"| `{r['model']}` | {cells} | {scores['total']} | {r['precision']:.2f} |")

    mean = round(sum(r["precision"] for r in records) / len(records), 4)
    passed = mean >= PRECISION_THRESHOLD
    verdict = (f"✅ **PASS** — mean precision `{mean:.2f}` ≥ `{PRECISION_THRESHOLD}`. "
               "PR ready for merge; backend can start."
               if passed else
               f"⛔ **BLOCKED** — mean precision `{mean:.2f}` < `{PRECISION_THRESHOLD}`. "
               "Improve the spec and push again.")

    return (
        f"## 🔎 Spec quality gate — `{spec_slug}`\n\n"
        f"Judge-scored SQL generated from this spec (Phase 2 automated gate).\n\n"
        f"{header}\n{divider}\n" + "\n".join(rows) + "\n\n"
        f"{verdict}\n"
    )


def main() -> int:
    args = parse_args()
    try:
        records = load_records(Path(args.out_dir), args.spec)
    except (FileNotFoundError, json.JSONDecodeError) as exc:
        sys.stderr.write(f"comment_pr error: {exc}\n")
        return 2

    markdown = render(args.spec, records)
    Path(args.out_file).write_text(markdown, encoding="utf-8")
    print(markdown)
    return 0


if __name__ == "__main__":
    sys.exit(main())
