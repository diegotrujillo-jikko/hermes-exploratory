# Hermes + Order Management Schema: Integration Guide

## What you have now

```
✅ Hermes Agent — installed and running
✅ wandb — 13 runs logged, analysis complete
✅ Experiment result — Spec B (~480 words) + Sonnet = sweet spot (86+ score)
✅ Quality rubric — 6 categories, 0-100 scale
```

## What you need to do (3 steps)

---

### Step 1: Install the skill in Hermes

```bash
# Copy the skill to Hermes's skill directory
cp -r order-mgmt-schema ~/.hermes/skills/order-mgmt-schema

# Verify it's loaded
hermes skills list | grep order-mgmt
```

After this, Hermes knows how to generate convention-compliant schemas.

---

### Step 2: Use it (3 ways)

#### A) Interactive mode (terminal UI)

```bash
hermes
```

Then type:

```
/order-mgmt-schema Generate a schema for order management: customers, orders, order_items, payments, shipments
```

Hermes will:
1. Read the SKILL.md (your validated conventions from the experiment)
2. Generate the SQL following all rules
3. Self-score against the rubric
4. Present the result with score breakdown

#### B) Direct command

```bash
hermes "Generate a PostgreSQL schema for inventory management: \
  products, warehouses, stock_levels, stock_movements. \
  Use the order-mgmt-schema skill."
```

#### C) With a spec file (for complex domains)

```bash
# Create a domain-specific spec (~480 words, your proven sweet spot)
cat > /tmp/users-spec.md << 'EOF'
# Domain: User Management

## Scope
- users (email, password_hash, name)
- profiles (avatar_url, bio, phone, address)
- roles (name, permissions jsonb)
- user_roles (many-to-many linking users and roles)

## Business rules
- Email must be unique
- Users can have multiple roles
- Soft delete on users (never hard delete)
- Profile is optional (1:1 with users, nullable FK)

## Out of scope
- Triggers, stored procedures, views
- Password reset tokens, sessions
- Seed data
EOF

# Tell Hermes to use the spec + skill together
hermes "Read /tmp/users-spec.md and generate the schema using order-mgmt-schema skill"
```

---

### Step 3: Track with wandb (observe the benefit)

#### Hermes runs are logged automatically if wandb/weave is configured.

Each schema generation creates a run with:
- Model used
- Tokens consumed
- Response time
- The generated SQL (as artifact)

#### To add your quality score:

```python
import wandb

run = wandb.init(project="hermes-exploratory", name="users-domain-sonnet")
run.log({
    "domain": "users",
    "model": "claude-sonnet-4.6",
    "spec_depth": "B",
    "score_structure": 29,
    "score_naming": 15,
    "score_integrity": 19,
    "score_comments": 12,
    "score_query_feasibility": 8,
    "score_spec_adherence": 10,
    "score_total": 93,
    "generation_time_seconds": 45,
})
run.finish()
```

#### Compare over time in wandb dashboard:

- X axis: `domain`
- Y axis: `score_total`
- Color: `model`

---

## How to see the benefit RIGHT NOW

### Demo 1: Before vs After

**Before (manual):**
```
1. Engineer opens pgAdmin
2. Writes CREATE TABLE statements from memory
3. Forgets COMMENT ON, forgets CHECK constraints
4. Reviewer finds 8 issues → 3 rounds of review
5. Total: 4-6 hours
```

**After (Hermes + Skill):**
```
1. Type: /order-mgmt-schema Generate schema for [domain]
2. Hermes generates SQL following all conventions
3. Self-scores: 86+ points
4. Reviewer finds 0-2 issues → 1 round of review
5. Total: 15-30 minutes
```

### Demo 2: Generate 3 schemas in 1 hour

```bash
# Domain 1
hermes "/order-mgmt-schema Generate schema for user management: \
  users, profiles, roles, user_roles"

# Domain 2
hermes "/order-mgmt-schema Generate schema for product catalog: \
  products, categories, product_categories, product_images"

# Domain 3
hermes "/order-mgmt-schema Generate schema for order management: \
  orders, order_items, payments, shipments"
```

Log each to wandb. Show the dashboard: 3 schemas in 1 hour vs 3 days manual.

### Demo 3: Model comparison (already done)

Your wandb already has the 13-run comparison:

```
Spec B scores across models:
  Opus 4.6:       91 pts
  DeepSeek V4 Pro: 90 pts
  Sonnet 4.6:     86 pts  ← default (best cost/quality)
  Kimi K2 Think:  87 pts
  Haiku 4.5:      80 pts
```

---

## Decision tree for daily use

```
Need a new schema?
  │
  ├─ Simple domain (3-5 tables)?
  │   └─ /order-mgmt-schema Generate schema for [domain]: [table list]
  │   └─ Score >= 80? → Use it
  │   └─ Score < 80? → Add more detail to your request, re-run
  │
  ├─ Complex domain (8+ tables)?
  │   └─ Write a domain spec (~480 words)
  │   └─ hermes "Read spec.md and generate schema using order-mgmt-schema skill"
  │   └─ Score >= 80? → Use it
  │   └─ Score < 80? → Improve spec, re-run
  │
  └─ Critical domain (financial, compliance)?
      └─ Write spec + switch to Opus
      └─ hermes model claude-opus-4.6
      └─ hermes "Read spec.md and generate schema using order-mgmt-schema skill"
      └─ Target: 91+ score
```

---

## Archive the experiment

The hermes-exploratory repo's purpose is complete:

```bash
cd hermes-exploratory
git add . && git commit -m "docs: Archive experiment — findings applied to Hermes skill"
```

The knowledge now lives in `~/.hermes/skills/order-mgmt-schema/`, not in the repo.
