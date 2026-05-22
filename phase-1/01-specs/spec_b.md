# Spec B — Balanced

## Domain

Order management for a small e-commerce backend. Customers place orders containing one or more products. Each order has a status lifecycle (pending → paid → shipped → delivered, or cancelled). Payments and shipments are tracked separately because a single order may have multiple payment attempts and may ship in multiple parcels.

## Scope

Design a PostgreSQL schema that supports:

- Customer accounts (email, hashed password, address).
- Product catalog (name, SKU, price, stock on hand).
- Orders with one or more line items, each referencing a product, quantity, and unit price captured at order time.
- Payments linked to orders (amount, method, status, processor reference).
- Shipments linked to orders (carrier, tracking number, status, shipped/delivered timestamps).
- Audit fields on every business table.

## Tech stack

- Database: PostgreSQL 16.
- Migrations: plain SQL in a single file.
- IDs: `BIGSERIAL` or `UUID` (pick one and apply consistently).
- Timezone: store all timestamps as `TIMESTAMPTZ` (UTC).

## Conventions

- Table names: plural `snake_case` (`customers`, `order_items`).
- Column names: `snake_case`.
- Primary key on every table: `id`.
- Foreign key columns: `{singular_table}_id` (e.g. `customer_id`, `order_id`).
- Boolean columns prefixed with `is_` or `has_`.
- Status columns: `VARCHAR` with a `CHECK` constraint listing valid values, OR a PostgreSQL `ENUM`. Pick one approach and apply consistently.
- Money: `NUMERIC(12, 2)` — never `FLOAT`/`REAL`.

## Integrity rules

- Every business table has `id`, `created_at`, `updated_at`, `deleted_at` (soft delete; nullable).
- Foreign keys declared with explicit `ON DELETE` behaviour:
  - `RESTRICT` for references that must not orphan (e.g. `order_items.order_id`).
  - `SET NULL` for optional references.
  - Never `CASCADE` on customer-owned data.
- Unique constraints: `customers.email`, `products.sku`, `payments.processor_reference`.
- `NOT NULL` on every column that is conceptually required (status, amounts, FK to parent).
- Quantities and amounts: `CHECK (value >= 0)` or `CHECK (value > 0)` where appropriate.

## Safe-change rules

- New columns must be nullable or have a default — no breaking `ALTER`s.
- Renames are forbidden in this schema — model it correctly the first time.
- Indexes on every foreign key column.
- Indexes on hot-path lookup columns (`orders.customer_id`, `orders.status`, `shipments.tracking_number`).

## Out of scope

- Triggers, stored procedures, views.
- Multi-currency, taxes, discounts, refunds.
- Seed data, test fixtures.

## Deliverable

A single `.sql` file with `CREATE TABLE` statements, constraints, and indexes. Order statements so dependencies resolve (parents before children).
