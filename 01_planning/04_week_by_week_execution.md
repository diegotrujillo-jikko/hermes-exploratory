# Execution Checklist: Hermes + wan.db Exploratory Phase

## Pre-Week 1: Setup & Alignment (This Week)

### Decisions to Make (1–2 hours)

- [ ] **Confirm problem scope with CEO/PM**
  - What domain? (Order mgmt, user auth, product catalog, etc.)
  - Does CEO agree it's separate from JikkoOps?
  - Timeline: 3 weeks to complete specs + testing?
  - Budget: Compute hours, token usage — any limits?

- [ ] **Coordinate with Diana (Hermes setup) and Juan David (wan.db guidance)**
  - Is Hermes already running on your team's machine?
  - Is wan.db configured to track offline (local) runs?
  - Which models will you test? (Sonnet, Opus, Haiku?)
  - Who owns credentials/API keys?

- [ ] **Agree on quality metrics**
  - What makes a "good" database schema output?
  - Create a rubric (structure adherence, naming consistency, data integrity, comments, etc.)
  - How will you score Spec A, B, C outputs numerically?

- [ ] **Create GitHub repo structure for this experiment**
  ```
  hermes-exploratory/
    /spec-variants
      spec_a_minimal.md
      spec_b_balanced.md
      spec_c_comprehensive.md
    /outputs
      round_1_sonnet_spec_a.sql
      round_1_sonnet_spec_b.sql
      round_1_sonnet_spec_c.sql
      round_2_opus_spec_a.sql
      ... etc
    /wan_db_logs
      round_1_metrics.json
      round_2_metrics.json
      round_3_metrics.json
    /analysis
      comparison_chart.png
      final_report.md
  ```

### Setup Tasks (1–2 hours)

- [ ] **Install/verify Hermes locally**
  - [ ] Anthropic API key configured
  - [ ] Model selection confirmed (Sonnet, Opus, Haiku available)
  - [ ] Telegram bot setup (optional, but useful for testing)
  - [ ] Test: Run a dummy prompt through Hermes to confirm it works

- [ ] **Install/verify wan.db**
  - [ ] Weights & Biases account created
  - [ ] Offline mode configured (local runs before cloud sync)
  - [ ] Test: Log a dummy run to confirm metrics capture works

- [ ] **Prepare your test environment**
  - [ ] Local PostgreSQL instance ready (or Docker PostgreSQL if preferred)
  - [ ] Test database created
  - [ ] SQL linter installed (if available; optional but useful)

---

## Week 1: Specification Design & Iteration

### Day 1–2: Draft Your 3 Specs

- [ ] **Spec A (Minimal, ~150 words)**
  - [ ] Write in markdown
  - [ ] Include: Project overview, Tech stack, Architecture
  - [ ] Save to: `/spec-variants/spec_a_minimal.md`
  - [ ] Self-review: Is this vague enough to cause hallucinations? Good.

- [ ] **Spec B (Balanced, ~480 words)**
  - [ ] Write in markdown
  - [ ] Include: All Spec A + Coding conventions, Data integrity, Placement rules, Safe change rules, Commands
  - [ ] Save to: `/spec-variants/spec_b_balanced.md`
  - [ ] Self-review: Is this actionable? Can a junior dev build from this?

- [ ] **Spec C (Comprehensive, ~900 words)**
  - [ ] Write in markdown
  - [ ] Include: All Spec B + Examples, Edge cases, Testing bar, Detailed commands
  - [ ] Save to: `/spec-variants/spec_c_comprehensive.md`
  - [ ] Self-review: Is this "everything you'd want to know"?

### Day 3: Peer Review & Refinement

- [ ] **Get feedback from Javier or Juan David**
  - [ ] Share all 3 specs
  - [ ] Ask: Are these realistic? Are the differences meaningful?
  - [ ] Update based on feedback
  - [ ] Commit final versions to GitHub

### Day 4–5: Create Scoring Rubric

- [ ] **Define your quality metrics** (use this as template)
  ```
  SCHEMA QUALITY RUBRIC (0–100)

  Category                  | Max Points | Scoring Criteria
  ---|---|---
  Structure (correct tables, relationships) | 30 | All required tables present? Foreign keys correct? (30: perfect, 20: 1–2 missing, 10: 3+ missing)
  Naming Conventions       | 15 | snake_case? ID naming correct? Timestamps present? (15: all correct, 10: 1–2 deviations, 5: multiple errors)
  Data Integrity           | 20 | Constraints appropriate? Nullable columns justified? Soft deletes handled? (20: excellent, 15: mostly good, 10: gaps)
  Comments & Clarity       | 15 | SQL documented? Reasoning explained? (15: comprehensive, 10: adequate, 5: minimal)
  Query Feasibility        | 10 | Can you answer key queries? Indexes suggested? (10: yes, 5: partial, 0: no)
  ---
  TOTAL                    | 100 |
  ```

- [ ] **Decide how to weight metrics in wan.db**
  - Will you log raw scores?
  - Weighted average?
  - Separate metrics per category?

---

## Week 2: Hermes Orchestration & Testing

### Test Round 1: Fix Model (Sonnet), Vary Specs

**Goal**: Does spec detail improve output quality when using the same model?

#### Setup (Day 1)

- [ ] **Prepare Hermes prompts**
  - [ ] Create a prompt template that feeds a spec to Hermes/Claude
  - [ ] Example:
    ```
    You are a database architect. Based on the following specification, generate a complete PostgreSQL schema.

    SPECIFICATION:
    [INSERT SPEC HERE]

    Requirements:
    1. Provide CREATE TABLE statements only (no migrations, no triggers)
    2. Include comments explaining design decisions
    3. Follow the naming conventions and constraints specified above
    4. Return valid, executable SQL

    BEGIN SCHEMA DESIGN:
    ```

- [ ] **Set up wan.db tracking**
  - [ ] Create project in wan.db named "Hermes Exploratory Phase"
  - [ ] Set up a run template to log:
    - test_id (e.g., "round_1_sonnet_spec_a")
    - model
    - spec_variant
    - output (path to SQL file)
    - quality_score (from your rubric)
    - raw_metrics (table_count, fk_count, etc.)

#### Run Tests (Day 2–3)

- [ ] **Run 1.1: Sonnet + Spec A**
  - [ ] Send Spec A to Hermes with Sonnet model
  - [ ] Capture output → save to `/outputs/round_1_sonnet_spec_a.sql`
  - [ ] Score using rubric → log to wan.db
  - [ ] Note any hallucinations or missing elements

- [ ] **Run 1.2: Sonnet + Spec B**
  - [ ] Send Spec B to Hermes with Sonnet model
  - [ ] Capture output → save to `/outputs/round_1_sonnet_spec_b.sql`
  - [ ] Score using rubric → log to wan.db
  - [ ] Compare to Run 1.1: Is output better? By how much?

- [ ] **Run 1.3: Sonnet + Spec C**
  - [ ] Send Spec C to Hermes with Sonnet model
  - [ ] Capture output → save to `/outputs/round_1_sonnet_spec_c.sql`
  - [ ] Score using rubric → log to wan.db
  - [ ] Compare to 1.1 and 1.2: Diminishing returns?

#### Analysis (Day 4)

- [ ] **Compare outputs in GitHub**
  - [ ] Run `diff` on the 3 SQL files (1.1 vs 1.2 vs 1.3)
  - [ ] Identify structural differences
  - [ ] Screenshot wan.db comparison chart
  - [ ] Document findings: "With Sonnet, Spec B achieved 92 points, Spec C achieved 95 — diminishing return of 3 points"

---

### Test Round 2: Fix Model (Opus), Vary Specs

**Goal**: Does Opus respond differently to spec variants than Sonnet? Is it more forgiving of minimal specs?

#### Setup (Day 1)

- [ ] Update Hermes configuration to use Opus model

#### Run Tests (Day 2–3)

- [ ] **Run 2.1: Opus + Spec A**
  - [ ] Send Spec A to Hermes with Opus model
  - [ ] Capture → save to `/outputs/round_2_opus_spec_a.sql`
  - [ ] Score, log to wan.db

- [ ] **Run 2.2: Opus + Spec B**
  - [ ] Send Spec B to Hermes with Opus model
  - [ ] Capture → save to `/outputs/round_2_opus_spec_b.sql`
  - [ ] Score, log to wan.db

- [ ] **Run 2.3: Opus + Spec C**
  - [ ] Send Spec C to Hermes with Opus model
  - [ ] Capture → save to `/outputs/round_2_opus_spec_c.sql`
  - [ ] Score, log to wan.db

#### Analysis (Day 4)

- [ ] **Compare Opus results to Sonnet**
  - [ ] Screenshot wan.db side-by-side: Sonnet vs. Opus
  - [ ] Document: "Opus scored 88/92/96 vs. Sonnet's 75/92/95. Opus is better with minimal specs (88 vs 75)."

---

### Test Round 3: Fix Spec (B = Balanced), Vary Models

**Goal**: Which model best understands the balanced spec? Trade-offs?

#### Setup (Day 1)

- [ ] Prepare to run the same Spec B through 3 models

#### Run Tests (Day 2)

- [ ] **Run 3.1: Sonnet + Spec B** (reuse from Round 1)
  - [ ] Already have output; score logged

- [ ] **Run 3.2: Opus + Spec B** (reuse from Round 2)
  - [ ] Already have output; score logged

- [ ] **Run 3.3: Haiku + Spec B**
  - [ ] Send Spec B to Hermes with Haiku model
  - [ ] Capture → save to `/outputs/round_3_haiku_spec_b.sql`
  - [ ] Score using rubric → log to wan.db

#### Analysis (Day 3–4)

- [ ] **Model comparison with fixed context**
  - [ ] Screenshot wan.db: Sonnet vs. Opus vs. Haiku (all fed Spec B)
  - [ ] Document: "Sonnet: 92 points, Opus: 92 points, Haiku: 78 points. Haiku struggles with complex data integrity rules; cost savings not justified."
  - [ ] Identify which model:
    - Best handles naming conventions?
    - Best identifies data integrity gaps?
    - Best includes comments?
    - Best generates optimized indexes?

---

## Week 3: Analysis & Documentation

### Day 1–2: Consolidate Findings

- [ ] **Create comparison matrix in `/analysis/comparison.md`**
  ```markdown
  # Test Results Summary

  ## Round 1: Sonnet with Varying Specs
  | Spec | Score | Table Count | FK Count | Hallucinations | Notes |
  |------|-------|-------------|----------|---|---|
  | A (Minimal) | 75 | 5 | 3 | 1 extra column | Missing soft-delete strategy |
  | B (Balanced) | 92 | 5 | 4 | 0 | Excellent; one missing index |
  | C (Comprehensive) | 95 | 5 | 4 | 0 | Perfect; detailed comments |

  ## Round 2: Opus with Varying Specs
  | Spec | Score | Table Count | FK Count | Hallucinations | Notes |
  |------|-------|-------------|----------|---|---|
  | A (Minimal) | 88 | 5 | 4 | 0 | Opus better with minimal context! |
  | B (Balanced) | 92 | 5 | 4 | 0 | Consistent with Sonnet |
  | C (Comprehensive) | 96 | 5 | 4 | 0 | Slightly better than Sonnet |

  ## Round 3: Multiple Models with Spec B
  | Model | Score | Strengths | Weaknesses |
  |-------|-------|-----------|-----------|
  | Sonnet | 92 | Speed, practical MVP focus | Missed edge case on cancelled orders |
  | Opus | 92 | Depth, risk identification | Slightly over-engineered |
  | Haiku | 78 | Cost-effective | Struggled with complex constraints |

  ## Key Findings
  1. **Spec depth matters, but with diminishing returns**: Spec B (balanced) achieved 92% of Spec C (comprehensive) quality with ~50% less context. **Recommendation: Use Spec B depth for JikkoOps.**
  2. **Opus is robust with minimal specs**: When specs are vague, Opus fills gaps better than Sonnet. **Recommendation: If specs are uncertain, use Opus.**
  3. **Haiku not recommended for complex schemas**: Cost savings (30%) don't justify quality loss (15%). **Recommendation: Stick with Sonnet for speed, Opus for depth.**
  4. **Hermes orchestration validated**: Running multiple models in parallel and comparing results reveals unique strengths (Opus found security risks, Sonnet nailed simplicity).
  5. **wan.db observability is essential**: Numbers-based comparison removes guesswork. Team can now say "this model/spec combo is 8 points better" instead of debating.
  ```

- [ ] **Extract key statistics**
  - [ ] Average score by model (Sonnet, Opus, Haiku)
  - [ ] Average score by spec depth (A, B, C)
  - [ ] Cost per test (token usage from API logs)
  - [ ] Quality-to-cost ratio (score / tokens spent)

### Day 2: Create HERMES_METHODOLOGY.md

- [ ] **Document your team's approach**
  ```markdown
  # Jikkosoft Hermes + Context Engineering Methodology

  ## Purpose
  When building new backend systems, we use Hermes orchestration + wan.db observability to validate that our context specifications (CLAUDE.md files) actually improve output quality.

  ## Process

  ### 1. Define Problem & Specs (Week 1)
  - Create 3 spec variants: minimal (A), balanced (B), comprehensive (C)
  - Follow the 10-section CLAUDE.md template
  - Get peer review before testing

  ### 2. Test with Hermes (Week 2)
  - Round 1: Fix Sonnet, vary specs → find optimal spec depth
  - Round 2: Fix Opus, vary specs → validate findings with different model
  - Round 3: Fix balanced spec, vary models → choose best model for your domain

  ### 3. Analyze & Document (Week 3)
  - Log all runs in wan.db (offline first, then sync)
  - Score each output using a shared rubric
  - Create comparison matrix
  - Extract actionable recommendations

  ## Scorecard Template (from our exploratory phase)

  [Copy the scoring rubric here]

  ## Recommendations for JikkoOps (from this experiment)

  - Use Spec B depth (balanced) for future projects
  - Run Sonnet + Opus parallel (Sonnet for MVP speed, Opus for risk identification)
  - Allocate 3 weeks for spec + test cycle before backend implementation
  - Track all metrics in wan.db for future comparison
  ```

### Day 3: Create Final Report

- [ ] **Write executive summary** (1 page)
  - What did we test?
  - What did we learn?
  - How does this apply to JikkoOps?

- [ ] **Prepare presentation for CEO/Juan David**
  - Screenshots of wan.db comparisons
  - Key metrics (score distribution, cost per test)
  - Recommendations for next phase

- [ ] **Commit everything to GitHub**
  - All 3 specs
  - All 6 SQL outputs (3 Sonnet runs + 3 Opus runs + 1 Haiku run)
  - Analysis markdown
  - HERMES_METHODOLOGY.md
  - Final report

---

## Week 4+: Apply to JikkoOps (After Design Finalization)

- [ ] **Wait for design team to finalize JikkoOps prototype**
  - [ ] This is your input gate; don't proceed until design is locked

- [ ] **Create JikkoOps-specific specs** using lessons from exploratory phase
  - [ ] Use Spec B depth as your baseline
  - [ ] Include domain-specific rules for operational systems

- [ ] **Run Hermes tests on JikkoOps specs**
  - [ ] Sonnet + Opus in parallel (from exploratory phase, we learned both are needed)
  - [ ] Log results in wan.db under a new project ("JikkoOps Schema Design")

- [ ] **Deliver refined database schema to backend** (you + colleague)
  - [ ] Based on validated specs + Hermes output + wan.db recommendations
  - [ ] CEO reviews for operational sign-off

---

## Quick Reference: Commands You'll Run

```bash
# Hermes: Feed a spec to Sonnet
hermes prompt --model sonnet --spec-file spec_b_balanced.md --output output.sql

# wan.db: Log a run (pseudo-code; adjust for your setup)
wandb init "Hermes Exploratory Phase"
wandb log({
  "test_id": "round_1_sonnet_spec_a",
  "model": "sonnet",
  "spec": "A",
  "quality_score": 75,
  "table_count": 5
})

# Test SQL locally
psql -U postgres -d test_db -f output.sql

# Compare outputs
diff output_sonnet_a.sql output_sonnet_b.sql > changes.diff
```

---

## Success Criteria (End of Week 3)

- [ ] All 7 outputs (SQL files) generated, tested, and committed
- [ ] All 7 runs logged in wan.db with consistent metrics
- [ ] Comparison matrix completed
- [ ] HERMES_METHODOLOGY.md written and team-reviewed
- [ ] Final report ready for CEO presentation
- [ ] Team agrees on "Spec B depth + Sonnet/Opus combo" for JikkoOps
- [ ] Clear timeline for applying this to JikkoOps (after design finalization)

---

**Ready to start? Pick your problem domain, draft Spec A, and schedule a 15-min sync with Juan David to get buy-in. Go.**

