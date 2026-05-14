#!/usr/bin/env python3
"""
Log a single Hermes run to W&B and append a JSONL record locally.

Usage:
    python scripts/log_run.py \
        --round 1 \
        --model sonnet-4-6 \
        --spec a \
        --output 02-outputs/r1_sonnet_a.sql \
        --notes "first pass"

Reads ANTHROPIC/WANDB keys from .env. JSONL written to 03-analysis/runs.jsonl.
W&B run uploads the SQL output as an artifact and logs spec/model/round as config.
"""
from __future__ import annotations

import argparse
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

from dotenv import load_dotenv

REPO_ROOT = Path(__file__).resolve().parent.parent
RUNS_JSONL = REPO_ROOT / "03-analysis" / "runs.jsonl"

VALID_SPECS = {"a", "b", "c"}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--round", type=int, required=True, choices=[1, 2, 3])
    parser.add_argument("--model", type=str, required=True,
                        help="model id, e.g. sonnet-4-6, opus-4-7, haiku-4-5")
    parser.add_argument("--spec", type=str, required=True, choices=sorted(VALID_SPECS))
    parser.add_argument("--output", type=str, required=True,
                        help="path to the .sql file produced by Hermes")
    parser.add_argument("--notes", type=str, default="")
    parser.add_argument("--no-wandb", action="store_true",
                        help="skip W&B upload (still writes JSONL)")
    return parser.parse_args()


def append_jsonl(record: dict) -> None:
    RUNS_JSONL.parent.mkdir(parents=True, exist_ok=True)
    with RUNS_JSONL.open("a", encoding="utf-8") as fh:
        fh.write(json.dumps(record, ensure_ascii=False) + "\n")


def log_to_wandb(record: dict, output_path: Path) -> None:
    import wandb

    project = os.environ.get("WANDB_PROJECT", "hermes-exploratory")
    entity = os.environ.get("WANDB_ENTITY") or None

    run = wandb.init(
        project=project,
        entity=entity,
        name=f"r{record['round']}_{record['model']}_{record['spec']}",
        config={
            "round": record["round"],
            "model": record["model"],
            "spec": record["spec"],
            "notes": record["notes"],
        },
        reinit=True,
    )
    artifact = wandb.Artifact(
        name=f"sql_r{record['round']}_{record['model']}_{record['spec']}",
        type="sql_output",
    )
    artifact.add_file(str(output_path))
    run.log_artifact(artifact)
    run.finish()


def main() -> int:
    load_dotenv(REPO_ROOT / ".env")
    args = parse_args()

    output_path = (REPO_ROOT / args.output).resolve()
    if not output_path.is_file():
        sys.stderr.write(f"error: output file not found: {output_path}\n")
        return 1

    record = {
        "round": args.round,
        "model": args.model,
        "spec": args.spec,
        "output": args.output,
        "notes": args.notes,
        "ts": datetime.now(timezone.utc).isoformat(timespec="seconds"),
    }
    append_jsonl(record)
    print(f"appended to {RUNS_JSONL.relative_to(REPO_ROOT)}")

    if args.no_wandb:
        print("skipped W&B (--no-wandb)")
        return 0

    if not os.environ.get("WANDB_API_KEY"):
        sys.stderr.write("warn: WANDB_API_KEY not set — skipping W&B upload\n")
        return 0

    log_to_wandb(record, output_path)
    print("logged to W&B")
    return 0


if __name__ == "__main__":
    sys.exit(main())
