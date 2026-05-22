# Spec 07 — Notifications

> Sample spec to exercise the `spec-gate` workflow end-to-end. Spec-B depth.

## Domain

In-app + email notification system over the order-management schema. Stores a
catalog of notification types, per-user delivery preferences, and one row per
delivered notification so read/unread state and audit history are queryable.

## Scope (tables)

- `notification_types` — code, title_template, body_template, default_channel
- `user_notification_prefs` — per (user, type) channel + enabled flag
- `notifications` — one delivered notification (recipient, type, channel, status, read_at)
- `notification_events` — delivery lifecycle rows (queued, sent, failed, bounced) per notification

## Tech stack

- PostgreSQL 16.
- Primary keys: `bigint generated always as identity`.
- FKs: `{referenced_table_singular}_id`.
- Timestamps: `timestamptz`, columns `created_at`, `updated_at`, `deleted_at` (nullable) for soft delete.

## Conventions

- snake_case for every identifier; plural table names.
- Status columns use a `CHECK` constraint, not native ENUM:
  - `notifications.status` ∈ (`pending`, `delivered`, `read`, `dismissed`).
  - `notification_events.event` ∈ (`queued`, `sent`, `failed`, `bounced`).
  - `channel` ∈ (`in_app`, `email`).
- No monetary columns in this domain.

## Integrity rules

- Soft delete on `notification_types` only; `notifications` and `notification_events` are immutable history.
- `user_notification_prefs`, `notifications` → `notification_types` via FK `ON DELETE RESTRICT`.
- `notification_events` → `notifications` via FK `ON DELETE CASCADE`.
- `UNIQUE (user_id, notification_type_id)` on `user_notification_prefs`.
- `notification_types.code` UNIQUE among non-deleted rows (partial unique index `WHERE deleted_at IS NULL`).
- `CHECK (read_at IS NULL OR status IN ('read','dismissed'))` on `notifications`.
- `NOT NULL` on every FK and every status/channel column.

## Safe-change rules

- New columns must be nullable or carry a default — no rewrite-locking changes.
- No column renames or drops.
- Index every FK column.
- Add an index on `notifications (recipient_id, created_at DESC)` for the inbox query
  and on `notifications (status)` for the unread-count scan.

## Out of scope

- Triggers, stored procedures, materialized views.
- The actual sending/transport layer, templating engine, auth.
- Seed data and partitioning.

## Deliverable

A single PostgreSQL `.sql` file: `CREATE TABLE` with PK/FK/CHECK/UNIQUE constraints,
the indexes above, and `COMMENT ON` for each table and non-obvious column. No prose,
no markdown fences.
