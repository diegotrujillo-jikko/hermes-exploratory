# Spec 06 — Reportes (reporting)

> Spec-B depth (~480 words): the sweet spot Phase 1 found (domain + conventions +
> integrity + safe-change rules). This is the file the image shows a designer
> pushing; editing it triggers the `spec-gate` workflow.

## Domain

Reporting layer over the order-management schema. Lets operators define saved
report definitions, schedule them, and store each generated run so results are
auditable and re-downloadable. Read-mostly; the heavy write path is run history.

## Scope (tables)

- `report_definitions` — name, description, owner, query template, output_format
- `report_parameters` — typed parameters bound to a definition (name, data_type, required, default_value)
- `report_schedules` — cron expression + timezone + enabled flag per definition
- `report_runs` — one row per execution (status, started_at, finished_at, row_count, error_message)
- `report_run_artifacts` — generated files per run (storage_uri, byte_size, content_type, checksum)

## Tech stack

- PostgreSQL 16.
- Primary keys: `bigint generated always as identity`.
- FKs: `{referenced_table_singular}_id`.
- Timestamps: `timestamptz`, columns `created_at`, `updated_at`, and `deleted_at` (nullable) for soft delete.

## Conventions

- snake_case for every identifier; plural table names.
- Status columns use a `CHECK` constraint, not native ENUM:
  - `report_runs.status` ∈ (`pending`, `running`, `succeeded`, `failed`).
  - `output_format` ∈ (`csv`, `xlsx`, `pdf`, `json`).
- Money/quantities are out of scope here (no monetary columns).
- `report_parameters.data_type` ∈ (`string`, `number`, `boolean`, `date`, `datetime`).

## Integrity rules

- Soft delete on `report_definitions` only; runs and artifacts are immutable history (hard rows, never updated after `finished_at`).
- `report_parameters`, `report_schedules`, `report_runs` → `report_definitions` via FK `ON DELETE RESTRICT` (cannot delete a definition with history).
- `report_run_artifacts` → `report_runs` via FK `ON DELETE CASCADE` (artifacts die with their run).
- `UNIQUE (definition_id, name)` on `report_parameters` (no duplicate parameter names per definition).
- `report_definitions.name` UNIQUE among non-deleted rows (partial unique index `WHERE deleted_at IS NULL`).
- `CHECK (finished_at IS NULL OR finished_at >= started_at)` on `report_runs`.
- `NOT NULL` on every FK and every status/format column.

## Safe-change rules

- New columns must be nullable or carry a default — no rewrite-locking changes.
- No column renames or drops in this migration.
- Index every FK column.
- Add an index on `report_runs (definition_id, started_at DESC)` for the "latest runs per report" query, and on `report_runs (status)` for the worker queue scan.

## Out of scope

- Triggers, stored procedures, materialized views.
- The actual query execution engine, auth/permissions, row-level security.
- Seed data and partitioning.

## Deliverable

A single PostgreSQL `.sql` file: `CREATE TABLE` statements with PK/FK/CHECK/UNIQUE
constraints, the indexes listed above, and `COMMENT ON` for each table and any
non-obvious column. No prose, no markdown fences.
