# Order management schema generation

Generate PostgreSQL schemas for e-commerce order management domains that score 86+ on a fixed quality rubric.

## When to use

- A new domain needs a database schema (customers, orders, inventory, payments, shipments)
- An existing schema needs new tables added
- You need a migration file for a domain change

## Context

This skill was derived from a 13-run context engineering experiment that proved:
- Spec depth ~480 words (balanced) produces the best cost/quality ratio
- Minimal specs (~150 words) average 60 points — too many hallucinated conventions
- Comprehensive specs (~900 words) average 96 — marginal gain for 2× the effort
- Default model: Claude Sonnet 4.6 (score 86 on balanced spec)
- Writing a better spec is 3× more effective than upgrading the model

## Instructions

When the user asks you to generate a schema, follow these steps:

### Step 1: Gather domain context

Ask the user for:
1. **Domain name** (e.g., "order management", "user accounts", "inventory")
2. **Table list** (e.g., "customers, orders, order_items, payments, shipments")
3. **Key business rules** (e.g., "orders can be cancelled only if not shipped")
4. **Out of scope** (e.g., "no triggers, no views, no seed data")

If the user provides a spec file, read it instead of asking.

### Step 2: Apply conventions (mandatory)

Every schema MUST follow these conventions regardless of domain:

**Tech stack:**
- PostgreSQL 16
- Single `.sql` file output
- IDs: pick `BIGSERIAL` or `UUID` consistently across all tables
- All timestamps: `TIMESTAMPTZ` (UTC)

**Naming:**
- Tables: plural `snake_case` (`customers`, `order_items`)
- Columns: `snake_case`
- Primary key on every table: `id`
- Foreign key columns: `{singular_table}_id` (e.g., `customer_id`, `order_id`)
- Boolean columns prefixed with `is_` or `has_`
- Money: `NUMERIC(12, 2)` — NEVER `FLOAT`/`REAL`

**Integrity (critical — this is where most points are lost):**
- Every business table: `id`, `created_at`, `updated_at`, `deleted_at` (soft delete; nullable)
- Foreign keys with explicit `ON DELETE`:
  - `RESTRICT` for must-not-orphan references
  - `SET NULL` for optional references
  - Never `CASCADE` on customer-owned data
- `NOT NULL` on every conceptually required column
- `CHECK` constraints on quantities and amounts (`>= 0` or `> 0`)
- `UNIQUE` constraints on natural keys (email, sku, tracking_number)
- Status columns: `VARCHAR` with `CHECK` listing valid values, or `ENUM` — pick one, apply consistently

**Safe-change rules:**
- New columns must be nullable or have a default — no breaking `ALTER`s
- Renames are forbidden — model it correctly the first time
- Indexes on every foreign key column
- Indexes on hot-path lookup columns (status, email, tracking)

### Step 3: Generate the SQL

Output a single `.sql` file with:
1. `CREATE TABLE` statements ordered by dependency (parents before children)
2. All constraints inline or immediately after
3. All indexes after table creation
4. `COMMENT ON TABLE` and `COMMENT ON COLUMN` for every table and non-obvious column

### Step 4: Self-score with rubric

After generating, evaluate against this rubric (0–100):

| Category | Points | What to check |
|----------|--------|---------------|
| Structure | 30 | Tables exist, columns correct, dependencies resolved |
| Naming | 15 | snake_case, FK pattern, boolean prefix |
| Integrity | 20 | ON DELETE explicit, CHECK constraints, UNIQUE, NOT NULL |
| Comments | 15 | COMMENT ON TABLE + COLUMN present |
| Query feasibility | 10 | Indexes on FKs and hot paths |
| Spec adherence | 10 | Followed conventions, nothing out of scope |

**Score < 80**: Fix the schema before presenting it.
**Score >= 80**: Present to user with the score breakdown.

## Example invocation

```
User: Generate a schema for order management with customers, orders, items, payments
Hermes: [reads SKILL.md] → [applies conventions] → [generates SQL] → [self-scores 86+] → [presents]
```

## Required environment variables

None — this skill uses only the active LLM provider.
