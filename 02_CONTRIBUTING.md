# Contributing to Hermes Exploratory Phase

This document guides team members on how to contribute.

## Roles

**Diego Trujillo** (Lead)
- Writes specs (A, B, C)
- Runs Hermes tests
- Leads analysis & final report

**Diana Plata** (Infrastructure)
- Sets up Hermes locally
- Configures wan.db
- Supports SQL execution

**Juan David Lopez** (Review & Guidance)
- Reviews specs before testing
- Guides context engineering
- Synthesizes findings

**Javier Toquica** (Peer Review)
- Reviews specs for completeness
- Audits SQL outputs

## Contribution Guidelines

### For Spec Writing (Diego)

1. Read `01_planning/02_spec_a_b_c_template.md`
2. Write in markdown (.md files)
3. Follow the structure: A=150, B=480, C=900 words
4. Keep no PII
5. Self-review for consistency
6. Commit message: `feat(spec): Add Spec [X] for [domain]`

### For Peer Review (Javier/Juan David)

1. Timeframe: Within 48 hours
2. Use review checklist
3. Comment on markdown file
4. Approval: ✅ when satisfied

### For Hermes Testing (Diana)

1. Confirm .env.example configured
2. Ensure Sonnet, Opus, Haiku available
3. SQL files named: `round_[N]_[model]_spec_[X].sql`
4. Validate each SQL locally
5. Commit & push

### For Metrics Logging (Juan David/Diego)

1. Use rubric: `01_planning/03_quality_rubric.md`
2. Rate each output 0–100
3. Record observations
4. Format: JSON in `04_wan_db_logs/`

### For Final Analysis (Diego)

1. Week 3, after all 7 outputs scored
2. Create comparison matrix: `05_analysis/`
3. Extract findings
4. Recommendations for JikkoOps

## Commit Message Format

```
<type>(<scope>): <subject>
```

Types: feat, fix, docs, chore
Scopes: spec, metrics, analysis, infra

Examples:
- `feat(spec): Add Spec B (balanced) for order management`
- `docs(analysis): Add comparison matrix`
- `chore(metrics): Log Round 1 results`

## File Naming

Specs:
- `spec_a_minimal.md`
- `spec_b_balanced.md`
- `spec_c_comprehensive.md`

SQL Outputs:
- `round_1_sonnet_spec_a.sql`
- `round_2_opus_spec_b.sql`
- `round_3_haiku_spec_b.sql`

Metrics:
- `round_1_metrics.json`
- `round_2_metrics.json`
- `round_3_metrics.json`

Analysis:
- `comparison_matrix.md`
- `hermes_methodology.md`
- `final_report.md`

---

**Happy exploring!** 🚀
