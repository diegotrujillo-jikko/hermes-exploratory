# CLAUDE.md Template for Exploratory Specs (Spec A, B, C)

This template shows you how to structure your 3 variants for the Hermes + wan.db experiment.

---

## SPEC A: Minimal Context (200 words max)

**Purpose**: Baseline test. Claude gets only project overview + tech stack. Expect hallucinations.

```markdown
# Order Management System Database

## Project Overview

This is a simple order management system for an e-commerce platform. It tracks customers, products, orders, and inventory. The business constraint is minimal—this is an MVP. We need to prove the concept works with a SQL database that can handle 10K orders/month initially, scaling to 100K within 6 months.

Target users: Internal operations team (5–10 people), external API consumers (third-party integrations).

## Tech Stack

- PostgreSQL 15+ (primary database)
- Node.js + Express (API layer—not our focus here)
- TypeScript (code generation will use TS types if needed)
- Do NOT use NoSQL, do NOT use multi-tenant schemas, keep it simple

## Architecture

Place all schema definitions in `/database/schema/`. We'll generate migrations after the schema is approved.

---

**Total: ~150 words. Nothing else. Let's see what Claude assumes.**
```

---

## SPEC B: Balanced Context (500 words max)

**Purpose**: Most practical. Includes all critical decision rules. Expect quality improvement.

```markdown
# Order Management System Database

## Project Overview

This is a simple order management system for an e-commerce platform. It tracks customers, products, orders, and inventory. The business constraint is minimal—this is an MVP. We need to prove the concept works with a SQL database that can handle 10K orders/month initially, scaling to 100K within 6 months.

Target users: Internal operations team (5–10 people), external API consumers (third-party integrations).

## Tech Stack

- PostgreSQL 15+ (primary database)
- Node.js + Express (API layer—not our focus here)
- TypeScript (code generation will use TS types if needed)
- Do NOT use NoSQL, do NOT use multi-tenant schemas, do NOT add audit tables or temporal versioning yet (Phase 2)
- All tables use UUID primary keys (not serial integers)
- Use lowercase snake_case for all column names

## Architecture

```
/database
  /schema
    - customers.sql
    - products.sql
    - orders.sql
    - order_items.sql
    - inventory.sql
  /migrations
    - [auto-generated]
```

Core entities: `customers`, `products`, `orders`, `order_items`, `inventory`.

Data flow: Customer places order → creates order record → creates order_items for each product → updates inventory. Queries must support: (1) order history per customer, (2) current inventory per product, (3) order status tracking.

## Coding Conventions

- All timestamps are UTC, stored as `created_at`, `updated_at` (automatic via trigger)
- Foreign keys use explicit naming: `{table}_id` (e.g., `customer_id`, `product_id`)
- Soft deletes: use `deleted_at` timestamp, never hard-delete unless explicitly asked
- No nullable foreign keys unless explicitly noted (strong referential integrity)
- Indexes: primary key + foreign keys auto-indexed; add composite indexes only for query patterns we've identified (see queries below)

## Data Integrity Rules

- A customer can have multiple orders; an order belongs to one customer
- An order_item always references an order and a product; never orphaned
- Inventory tracks quantity_on_hand; decrements when order is placed (not when shipped)
- Orders have status enum: `pending`, `processing`, `shipped`, `delivered`, `cancelled`
- A cancelled order must restore inventory quantities

## File & Content Placement Rules

- One entity = one SQL file (customers.sql, products.sql, etc.)
- If you need to modify an existing table, add an ALTER TABLE in the same file with a `-- v2: ...` comment
- Do NOT create intermediate junction tables unless explicitly asked (we'll add many-to-many later)
- Do NOT add trigger definitions in the main schema files; we'll create a separate `/triggers` folder if needed

## Safe Change Rules

- Do NOT modify the primary key strategy after schema approval (changing from UUID to serial = expensive migration)
- Do NOT add new tables without asking first (prevents schema sprawl)
- Do NOT remove columns; mark as deprecated with a comment instead

## Specific Commands

```bash
# Validate schema
psql -U postgres -f /database/schema/customers.sql --dry-run

# Apply all schemas (in order)
psql -U postgres -f /database/schema/customers.sql
psql -U postgres -f /database/schema/products.sql
psql -U postgres -f /database/schema/orders.sql
psql -U postgres -f /database/schema/order_items.sql
psql -U postgres -f /database/schema/inventory.sql
```

---

**Total: ~480 words. Clear structure, decision rules, safety constraints. Expect much better output.**
```

---

## SPEC C: Comprehensive Context (800–1000 words)

**Purpose**: "Everything you'd want to know." Includes examples, edge cases, testing expectations. Expect near-optimal output.

```markdown
# Order Management System Database

## Project Overview

This is a simple order management system for an e-commerce platform. It tracks customers, products, orders, and inventory. The business constraint is minimal—this is an MVP. We need to prove the concept works with a SQL database that can handle 10K orders/month initially, scaling to 100K within 6 months.

Target users: Internal operations team (5–10 people), external API consumers (third-party integrations).

Current business model: B2B SaaS (single tenant for now; multi-tenancy deferred).

## Tech Stack

- PostgreSQL 15+ (primary database)
- Node.js + Express (API layer—not our focus here)
- TypeScript (schema types will be auto-generated if needed)
- Do NOT use NoSQL, do NOT use multi-tenant schemas, do NOT add audit tables or temporal versioning yet (Phase 2)
- Do NOT use ORMs (raw SQL in migrations; ORMs added in Phase 2)
- All tables use UUID primary keys (not serial integers)
- Use lowercase snake_case for all column names; no abbreviations (customer_name, not cust_nm)

## Architecture

```
/database
  /schema
    - customers.sql          (core: id, email, name, created_at, updated_at, deleted_at)
    - products.sql          (core: id, sku, name, price_cents, active, created_at, updated_at)
    - orders.sql            (core: id, customer_id, status, total_price_cents, created_at, updated_at)
    - order_items.sql       (junction: id, order_id, product_id, quantity, unit_price_cents)
    - inventory.sql         (core: id, product_id, quantity_on_hand, quantity_reserved)
  /migrations
    - [auto-generated, one per deployed change]
  /triggers
    - [future: auto-timestamp, inventory updates]
  /queries
    - order_history.sql     (reference queries for common patterns)
```

**Critical Data Flow:**
1. Customer registers → created in `customers` table
2. Admin adds products → created in `products` table with initial inventory in `inventory` table
3. Customer places order → creates row in `orders`, rows in `order_items`, decrements `inventory.quantity_on_hand`
4. Order status progresses: pending → processing → shipped → delivered (or cancelled → restore inventory)

**Database Design Principles:**
- Normalized to 3NF (no denormalization for MVP)
- Referential integrity enforced at database layer (FK constraints)
- Immutable history: use `created_at`, `updated_at`, `deleted_at` for auditing; no hard deletes
- No application logic in triggers (Phase 2); all logic in API

## Coding Conventions

### Naming
- All timestamps: `created_at` (auto-set on insert), `updated_at` (auto-set on update), `deleted_at` (soft delete marker)
- All money: `*_price_cents` or `*_cost_cents` (store as INTEGER cents, never floats)
- All IDs: column name is `id` (PRIMARY KEY UUID), foreign keys are `{table_singular}_id` (e.g., `customer_id`, `product_id`)
- Boolean flags: `is_*` or `has_*` (e.g., `is_active`, `has_inventory`)

### Data Types
- IDs: `UUID DEFAULT gen_random_uuid()`
- Prices: `INTEGER` (cents; 100 = $1.00)
- Quantities: `INTEGER` (not decimal)
- Timestamps: `TIMESTAMP DEFAULT CURRENT_TIMESTAMP` for created_at; no timezone suffix (assume UTC)
- Strings: `VARCHAR(255)` for names/emails, `TEXT` for descriptions
- Enums: defined inline or as PostgreSQL ENUM type (your choice; inline for MVP)

### Constraints
- NOT NULL on: id, created_at, updated_at, all foreign keys (except soft-delete scenarios)
- NOT NULL can be relaxed only with explicit comment: `-- nullable: allows XYZ to be optional`
- Foreign keys: explicit CASCADE on delete for soft-deletes only; otherwise RESTRICT (prevent orphans)
- Unique constraints: email on customers, sku on products

### Indexes
- Auto-indexed: PRIMARY KEY, FOREIGN KEYS
- Composite indexes for query patterns:
  - `orders (customer_id, created_at)` — for "all orders by customer, sorted by date"
  - `order_items (order_id)` — for "all items in order"
  - `inventory (product_id)` — for "inventory by product"
- Do NOT add speculative indexes; add only after profiling

## Data Integrity Rules

### Customers
- Email is UNIQUE and NOT NULL
- Name is required
- A customer can have 0 to many orders

### Products
- SKU is UNIQUE and NOT NULL (external reference)
- Price is in cents, >= 0
- Only active products can be ordered (enforce at API layer; schema has is_active flag)

### Orders
- Status is enum: pending, processing, shipped, delivered, cancelled
- Initial status is always pending
- Total price = sum of (order_items.quantity * order_items.unit_price_cents)
- An order can have 1 to many order_items; never empty

### Order Items
- Quantity >= 1, must be integer
- Unit price (in cents) is snapshot at order time; if product price changes later, order_item price doesn't
- One row per (order, product) pair; no duplicates

### Inventory
- Tracks both `quantity_on_hand` and `quantity_reserved`
- `quantity_on_hand` >= `quantity_reserved` (invariant)
- When order is placed: `quantity_reserved` += quantity ordered
- When order is shipped: `quantity_on_hand` -= quantity ordered, `quantity_reserved` -= quantity ordered
- If order cancelled: both reversed

## File & Content Placement Rules

- **One entity = one SQL file**: customers.sql, products.sql, orders.sql, order_items.sql, inventory.sql
- **Modification pattern**: If updating a table, add ALTER TABLE statement in the same file with version comment:
  ```sql
  -- v2: Add support for international addresses
  ALTER TABLE customers ADD COLUMN country_code VARCHAR(2);
  ```
- **No intermediate tables yet**: We don't have many-to-many relationships in MVP (e.g., no product_categories junction). Add only if explicitly requested.
- **Trigger logic**: Defer to Phase 2. For now, timestamps and inventory updates are handled at API layer.

## Safe Change Rules (Do NOT Do These)

- Do NOT change primary key strategy after schema approval (UUID is locked in)
- Do NOT hard-delete any table or column (use soft deletes with deleted_at)
- Do NOT add new tables without explicit request (prevents schema sprawl)
- Do NOT modify foreign key constraints without asking (breaks referential integrity)
- Do NOT rename columns in production without a migration + deprecation period
- Do NOT add application logic to triggers; keep schema simple

## Testing & Quality Bar

Schema is done when:
1. All CREATE TABLE statements are syntactically valid (psql validates)
2. Foreign key relationships form a directed acyclic graph (no circular references)
3. Sample inserts work: can insert customer → product → order → order_item without errors
4. Soft delete works: mark deleted_at, verify WHERE deleted_at IS NULL filters correctly
5. A cancelled order correctly restores inventory (API will handle this; verify logic is possible in schema)

## Specific Commands

```bash
# Validate syntax (dry-run, no changes)
psql -U postgres -d test_db -f /database/schema/customers.sql

# Apply schemas in order (safe, idempotent)
psql -U postgres -d test_db < /database/schema/customers.sql
psql -U postgres -d test_db < /database/schema/products.sql
psql -U postgres -d test_db < /database/schema/orders.sql
psql -U postgres -d test_db < /database/schema/order_items.sql
psql -U postgres -d test_db < /database/schema/inventory.sql

# Test a sample transaction
psql -U postgres -d test_db << EOF
INSERT INTO customers (id, email, name) VALUES (gen_random_uuid(), 'test@example.com', 'Test User');
INSERT INTO products (id, sku, name, price_cents) VALUES (gen_random_uuid(), 'SKU001', 'Widget', 9999);
-- etc.
EOF

# Inspect final schema
\dt — (in psql)
```

---

**Total: ~900 words. Complete, opinionated, ready to feed to Claude. Expect optimal output and fewer questions.**
```

---

## How to Use These 3 Specs in Your Experiment

### Test Structure

**Test Round 1: Fix Model (Sonnet), Vary Specs**

```
Input Spec A to Sonnet → Output A1
Input Spec B to Sonnet → Output B1
Input Spec C to Sonnet → Output C1

Measure: Is Output C1 significantly better than A1? At what diminishing return point?
```

**Test Round 2: Fix Model (Opus), Vary Specs**

```
Input Spec A to Opus → Output A2
Input Spec B to Opus → Output B2
Input Spec C to Opus → Output C2

Measure: Does Opus behave similarly to Sonnet? Does Opus handle minimal specs better?
```

**Test Round 3: Fix Spec (B = Balanced), Vary Models**

```
Input Spec B to Sonnet → Output B1
Input Spec B to Opus → Output B2
Input Spec B to Haiku → Output B3

Measure: Which model best understood the balanced spec? Trade-offs?
```

### What to Capture in wan.db

For each run, log:

```json
{
  "test_id": "round_1_spec_a_sonnet",
  "spec_variant": "A (minimal)",
  "model": "sonnet",
  "output_metrics": {
    "table_count": 5,           // did it create the right number?
    "fk_relationships": 4,      // correct relationships?
    "nullable_columns_count": 2, // over-nullable?
    "hallucinated_columns": 0,   // made-up columns?
    "follows_naming_conventions": true, // snake_case?
    "missing_required_constraints": 0   // forgot NOT NULL?
  },
  "quality_score": 85,          // subjective 0–100
  "notes": "Missing inventory soft-delete strategy; otherwise good"
}
```

This gives wan.db a clear comparison axis.

---

## Summary: Your 3 Specs

| Aspect | Spec A (Minimal) | Spec B (Balanced) | Spec C (Comprehensive) |
|--------|-----------------|------------------|------------------------|
| **Word Count** | ~150 | ~480 | ~900 |
| **Sections** | Overview, Tech Stack, Architecture | + Coding Conventions, Data Integrity, Placement Rules, Safety Rules | + Examples, Edge Cases, Testing Bar, Detailed Commands |
| **Detail Level** | Skeleton | Decision Rules | Complete Reference |
| **Use Case** | Baseline; expect gaps | MVP Standard | Best-case scenario |
| **Effort to Write** | 30 min | 1.5 hrs | 2.5 hrs |

---

## Pro Tips for Your Experiment

1. **Timestamp everything** in wan.db (when you ran it, which team member initiated, any notes)
2. **Keep outputs in version control** (check in the SQL each model generated; makes diffs easy)
3. **Create a scoring rubric** before you run tests (don't decide quality after the fact)
4. **Take screenshots** of wan.db comparisons for your final report
5. **Invite Javier or Juan David to one run** (shows observability in action, builds buy-in)

---

This is your template. Copy, adapt, and let the models show you the difference context makes. 🚀
