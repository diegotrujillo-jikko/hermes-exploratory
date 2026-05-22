# Spec C — Comprehensive

## Domain

Order management for a small e-commerce backend. Customers place orders containing one or more products. Each order moves through a status lifecycle and may have multiple payment attempts and multiple shipments (split parcels). The schema must support common operational queries (customer order history, daily revenue, low-stock alerts) and remain safe to evolve without destructive migrations.

## Status lifecycles

**Order status**: `pending` → `paid` → `shipped` → `delivered`. Terminal cancellation: `pending` → `cancelled` or `paid` → `cancelled` (refund handled by payments).

**Payment status**: `initiated` → `authorized` → `captured`, or `initiated` → `failed`, or `captured` → `refunded`.

**Shipment status**: `label_created` → `in_transit` → `delivered`, or any state → `returned`.

Transitions are enforced in application code, not in SQL — but the schema must store enough state to make invalid combinations detectable (e.g. an order cannot be `delivered` if no shipment is `delivered`).

## Scope

Tables required:

1. `customers` — account holder. Email (unique), hashed password, full name, phone, default shipping address (denormalised JSON or FK to `addresses`).
2. `addresses` — separate table since a customer may have multiple addresses and addresses may be reused across orders. Link via `customer_id`.
3. `products` — SKU (unique), name, description, price (current), stock_on_hand. Soft-deletable.
4. `orders` — header. `customer_id`, `status`, `total_amount` (snapshot of sum of line items at placement), `placed_at`, `shipping_address_id`, `billing_address_id`.
5. `order_items` — child of `orders`. `order_id`, `product_id`, `quantity`, `unit_price` (snapshot at order time, NOT a live join to `products.price`).
6. `payments` — `order_id`, `amount`, `method` (card/transfer/cash_on_delivery), `status`, `processor_reference` (unique), `processed_at`.
7. `shipments` — `order_id`, `carrier`, `tracking_number` (unique), `status`, `shipped_at`, `delivered_at`.
8. `shipment_items` — many-to-many between shipments and order_items, since a single order_item can be split across shipments.

## Tech stack

- Database: PostgreSQL 16.
- Migrations: plain SQL in a single file. Statements ordered so parents precede children.
- IDs: `BIGSERIAL` (monotonic insert performance preferred over UUID for this scope).
- Timestamps: `TIMESTAMPTZ`, default `NOW()`, stored UTC.
- No ORM. No triggers. No stored procedures. No views.

## Conventions

- Tables: plural `snake_case` (`customers`, `order_items`, `shipment_items`).
- Columns: `snake_case`.
- Primary key: `id BIGSERIAL PRIMARY KEY`.
- Foreign keys: `{singular_table}_id`.
- Booleans: `is_` / `has_` prefix.
- Status columns: `VARCHAR(32)` with `CHECK (status IN (...))` listing the allowed transitions. Prefer `CHECK` over PostgreSQL `ENUM` to avoid the ALTER-TYPE migration trap.
- Money: `NUMERIC(12, 2)` exclusively.
- Quantity: `INTEGER CHECK (quantity > 0)`.

## Integrity

- Every business table has: `id`, `created_at`, `updated_at`, `deleted_at` (nullable, for soft delete).
- `NOT NULL` on every required field. Optional fields explicitly nullable.
- Foreign key `ON DELETE` policy:
  - `order_items.order_id` → `RESTRICT` (history is immutable).
  - `order_items.product_id` → `RESTRICT` (cannot orphan a sold item).
  - `payments.order_id`, `shipments.order_id` → `RESTRICT`.
  - `shipment_items.shipment_id`, `shipment_items.order_item_id` → `CASCADE` only for the join table itself (acceptable since it has no independent meaning).
  - `addresses.customer_id` → `RESTRICT`.
  - `orders.shipping_address_id`, `orders.billing_address_id` → `RESTRICT` (history preservation).
- Unique constraints:
  - `customers.email` (case-insensitive: use `CITEXT` or a `LOWER(email)` unique index).
  - `products.sku`.
  - `payments.processor_reference`.
  - `shipments.tracking_number`.
  - `(shipment_id, order_item_id)` on `shipment_items` (composite unique).
- Check constraints:
  - All money columns: `CHECK (amount >= 0)`.
  - `order_items.quantity > 0`.
  - `products.stock_on_hand >= 0`.

## Indexes

- Every foreign key column gets an index.
- Composite indexes for hot paths:
  - `orders (customer_id, placed_at DESC)` — customer order history.
  - `orders (status, placed_at)` — operational dashboards.
  - `payments (order_id, status)`.
- Partial index for soft delete: `WHERE deleted_at IS NULL` on each large table.

## Safe-change rules

- All future `ALTER TABLE ADD COLUMN` must be nullable or `DEFAULT` a constant.
- No renames in this schema — name correctly the first time.
- No `DROP COLUMN` planned. If a column becomes obsolete, mark it deprecated in comments and stop writing to it.
- Indexes added later must use `CREATE INDEX CONCURRENTLY` (note in comments).

## Edge cases to handle

- A product price changes after orders are placed: `order_items.unit_price` is a snapshot; never join back to `products.price` for historical totals.
- A customer is "deleted": soft delete only. Orders remain, payments remain, audit trail intact.
- Partial shipments: one `order_item` of quantity 10 may be split across two shipments (6 + 4). `shipment_items` carries its own `quantity` column.
- Failed payment then successful retry: both rows exist in `payments`; order moves to `paid` only when one row is `captured`.
- Refund: a new `payments` row with negative `amount` and `status = 'refunded'`, referencing the same `order_id`.

## Comments

Use SQL `COMMENT ON TABLE` and `COMMENT ON COLUMN` for:

- Every table (one line: what it represents).
- Every status column (list the allowed values and the lifecycle).
- Every snapshot column (`unit_price`, `total_amount`) — explain why it is not a live join.
- Every soft-delete column.

## Testing bar

The submitted SQL is judged by:

1. **Runs cleanly**: `psql -f schema.sql` on an empty PostgreSQL 16 database succeeds with no errors and no warnings.
2. **Idempotent re-run is not required** — a single clean run is sufficient.
3. **Required tables present**: all 8 from Scope.
4. **No invented tables** not asked for (no `tags`, `coupons`, `users` distinct from `customers`, etc.).
5. **All FK + unique + check constraints declared**.
6. **All indexes from the Indexes section present**.
7. **Comments present on every table and on the columns called out above**.

## Out of scope

- Triggers, stored procedures, views, materialised views.
- Authentication tables beyond `customers` (no `sessions`, `tokens`).
- Multi-currency, tax engines, discount codes, gift cards.
- Inventory reservations, warehouses, multi-location stock.
- Seed data, test fixtures, sample inserts.

## Deliverable

A single `.sql` file containing only `CREATE TABLE`, `CREATE INDEX`, and `COMMENT ON` statements. Ordered so that referenced tables are created before referencing tables.
