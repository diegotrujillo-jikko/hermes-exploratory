#!/usr/bin/env python3
"""
Phase 2 — evaluate one spec with one generator model (image steps 3-4).

Pipeline (faithful automation of Phase 1):
  1. Read the spec under review.
  2. Generator model produces a PostgreSQL schema from the spec.
  3. Judge model scores that SQL against the 6-category rubric (LLM-as-judge).
  4. precision = rubric_total / 100. Result written as JSON; optionally logged to W&B.

Usage:
    python evaluate_spec.py \
        --spec ../specs/spec-06-reportes.md \
        --model claude-sonnet-4-6 \
        --judge claude-opus-4-7 \
        --out-dir .eval-out

Requires ANTHROPIC_API_KEY. W&B upload happens only if WANDB_API_KEY is set.
Exit code is always 0 on a successful evaluation — the pass/fail decision lives
in gate.py so that a low score still produces a PR comment before the block.
"""
from __future__ import annotations

import argparse
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

from dotenv import load_dotenv

sys.path.insert(0, str(Path(__file__).resolve().parent))
from rubric import precision_of, total_of, validate_scores  # noqa: E402

PHASE2_ROOT = Path(__file__).resolve().parent.parent
REPO_ROOT = PHASE2_ROOT.parent

GENERATION_PROMPT = (
    "Generate the PostgreSQL schema described by the spec above. "
    "Output only the .sql file contents — no commentary, no markdown fences, no prose."
)

# System prompt for the judge. Cached (it is constant across every run) to cut cost.
JUDGE_SYSTEM = (
    "You are a strict database schema reviewer. Score the candidate PostgreSQL "
    "schema against this rubric and return ONLY a JSON object with integer keys "
    "structure (0-30), naming (0-15), integrity (0-20), comments (0-15), "
    "query_feasibility (0-10), spec_adherence (0-10). No prose, no markdown.\n\n"
    "structure: required tables, FK relationships, no hallucinated tables.\n"
    "naming: snake_case, id/{table}_id, created_at/updated_at/deleted_at.\n"
    "integrity: PK/FK, NOT NULL, UNIQUE, soft delete, CASCADE/RESTRICT.\n"
    "comments: tables and non-obvious decisions documented.\n"
    "query_feasibility: key queries supported, indexes on FK + hot paths.\n"
    "spec_adherence: followed spec, no invented features."
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--spec", required=True, help="path to the spec markdown file")
    parser.add_argument("--model", required=True, help="generator model id")
    parser.add_argument("--judge", required=True, help="judge model id")
    parser.add_argument("--out-dir", default=str(PHASE2_ROOT / ".eval-out"),
                        help="directory for generated SQL + scores JSON")
    parser.add_argument("--gen-max-tokens", type=int, default=4096)
    parser.add_argument("--judge-max-tokens", type=int, default=1024)
    parser.add_argument("--no-wandb", action="store_true", help="skip W&B upload")
    return parser.parse_args()


def read_spec(spec_arg: str) -> tuple[str, str]:
    """Return (spec_slug, spec_text). Validates the file exists. Fails fast."""
    spec_path = Path(spec_arg)
    if not spec_path.is_absolute():
        spec_path = (Path.cwd() / spec_path).resolve()
    if not spec_path.is_file():
        raise FileNotFoundError(f"spec not found: {spec_path}")
    return spec_path.stem, spec_path.read_text(encoding="utf-8")


def make_client():
    """Construct the Anthropic client; fail fast with a clear message if no key."""
    if not os.environ.get("ANTHROPIC_API_KEY"):
        raise RuntimeError("ANTHROPIC_API_KEY is not set — cannot evaluate spec")
    from anthropic import Anthropic

    return Anthropic()


def generate_sql(client, model: str, spec_text: str, max_tokens: int) -> str:
    """Call the generator model to produce SQL from the spec."""
    message = client.messages.create(
        model=model,
        max_tokens=max_tokens,
        messages=[{
            "role": "user",
            "content": f"{spec_text}\n\n{GENERATION_PROMPT}",
        }],
    )
    return "".join(block.text for block in message.content if block.type == "text").strip()


def judge_sql(client, judge: str, spec_text: str, sql: str, max_tokens: int) -> dict[str, int]:
    """Call the judge model; return validated category scores."""
    message = client.messages.create(
        model=judge,
        max_tokens=max_tokens,
        system=[{
            "type": "text",
            "text": JUDGE_SYSTEM,
            "cache_control": {"type": "ephemeral"},  # constant across runs -> cache it
        }],
        messages=[{
            "role": "user",
            "content": f"SPEC:\n{spec_text}\n\nCANDIDATE SQL:\n{sql}\n\nReturn the JSON scores now.",
        }],
    )
    raw = "".join(block.text for block in message.content if block.type == "text").strip()
    return validate_scores(_parse_json_object(raw))


def _parse_json_object(raw: str) -> dict:
    """Extract the first JSON object from a model reply, tolerating stray fences."""
    start, end = raw.find("{"), raw.rfind("}")
    if start == -1 or end == -1 or end < start:
        raise ValueError(f"judge did not return a JSON object: {raw[:200]!r}")
    return json.loads(raw[start:end + 1])


def log_to_wandb(record: dict, sql_path: Path) -> None:
    import wandb

    project = os.environ.get("WANDB_PROJECT", "hermes-exploratory")
    entity = os.environ.get("WANDB_ENTITY") or None
    run = wandb.init(
        project=project, entity=entity,
        name=f"gate_{record['spec']}_{record['model']}",
        config={"phase": 2, "spec": record["spec"], "model": record["model"]},
        reinit=True,
    )
    run.log({**record["scores"], "precision": record["precision"]})
    artifact = wandb.Artifact(name=f"sql_{record['spec']}_{record['model']}", type="sql_output")
    artifact.add_file(str(sql_path))
    run.log_artifact(artifact)
    run.finish()


def main() -> int:
    load_dotenv(REPO_ROOT / ".env")
    args = parse_args()

    spec_slug, spec_text = read_spec(args.spec)
    client = make_client()

    sql = generate_sql(client, args.model, spec_text, args.gen_max_tokens)
    scores = judge_sql(client, args.judge, spec_text, sql, args.judge_max_tokens)
    scores_with_total = {**scores, "total": total_of(scores)}

    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    sql_path = out_dir / f"{spec_slug}__{args.model}.sql"
    sql_path.write_text(sql + "\n", encoding="utf-8")

    record = {
        "spec": spec_slug,
        "model": args.model,
        "judge": args.judge,
        "generated_sql_path": str(sql_path.relative_to(PHASE2_ROOT)),
        "scores": scores_with_total,
        "precision": precision_of(scores),
        "ts": datetime.now(timezone.utc).isoformat(timespec="seconds"),
    }
    scores_path = out_dir / f"{spec_slug}__{args.model}.json"
    scores_path.write_text(json.dumps(record, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(record, ensure_ascii=False))

    if not args.no_wandb and os.environ.get("WANDB_API_KEY"):
        log_to_wandb(record, sql_path)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:  # surface a clear CI error, never swallow
        sys.stderr.write(f"evaluate_spec error: {exc}\n")
        sys.exit(2)
