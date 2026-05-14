# Hermes Exploratory Phase

Test how **context engineering** improves LLM-generated database schemas using **Hermes orchestration** + **Weights & Biases observability**.

**Result**: Data-driven approach to schema design that scales to JikkoOps.

---

## 🚀 Getting Started

### First Time? Start Here

1. **Read** `01_QUICKSTART.md` (5 min)
2. **Pick a problem** (order mgmt, auth, product catalog — NOT JikkoOps yet)
3. **Draft Spec A** using `01_planning/02_spec_a_b_c_template.md`
4. **Commit to Git** with conventional commit message
5. **Get peer review** from Javier/Juan David

---

## 📚 Documentation Map

### For Beginners
- `01_QUICKSTART.md` — "I'm starting now" guide
- `02_CONTRIBUTING.md` — How the team works together

### For Deep Dives (Week 1)
- `01_planning/01_claude_md_to_hermes_strategy.md` — Why this approach works
- `01_planning/02_spec_a_b_c_template.md` — Write your 3 specs here
- `01_planning/03_quality_rubric.md` — How to score outputs (0–100)
- `01_planning/04_week_by_week_execution.md` — Detailed daily checklist

### For Execution (Week 2–3)
- `02_spec-variants/README.md` — Where to create specs
- `03_outputs/README.md` — Where Hermes-generated SQL lives
- `04_wan_db_logs/README.md` — Metrics tracking guide
- `05_analysis/README.md` — How to analyze results

---

## 📋 Project Structure

```
hermes-exploratory/
├── README.md                                 ← YOU ARE HERE (entry point)
├── 01_QUICKSTART.md                         ← START HERE if new
├── 02_CONTRIBUTING.md                       ← Team collaboration guide
├── 03_REPO_SUMMARY.md                       ← Repo review
├── 04_.env.example                          ← Copy to .env locally
├── .gitignore
│
├── 01_planning/                             ← Strategic guides
│   ├── 01_claude_md_to_hermes_strategy.md       (philosophy + approach)
│   ├── 02_spec_a_b_c_template.md               (templates for 3 specs)
│   ├── 03_quality_rubric.md                    (0–100 scoring system)
│   └── 04_week_by_week_execution.md            (day-by-day checklist)
│
├── 02_spec-variants/                        ← YOU CREATE THESE
│   ├── README.md
│   ├── spec_a_minimal.md              (~150 words)
│   ├── spec_b_balanced.md             (~480 words) ← STANDARD
│   └── spec_c_comprehensive.md        (~900 words)
│
├── 03_outputs/                              ← Hermes-generated SQL (7 files)
│   └── README.md
│
├── 04_wan_db_logs/                          ← Metrics & observability
│   └── README.md
│
└── 05_analysis/                             ← Your findings & report
    ├── README.md
    ├── comparison_matrix.md
    ├── hermes_methodology.md
    └── final_report.md
```

---

## 🎯 The Experiment (3 Weeks)

### Week 1: Write Specifications
Create 3 CLAUDE.md-style specs for a small problem:
- **Spec A (Minimal)**: ~150 words → expect gaps
- **Spec B (Balanced)**: ~480 words → your team standard
- **Spec C (Comprehensive)**: ~900 words → everything needed

### Week 2: Run Hermes Tests
Generate 7 SQL schemas via Hermes:
- **Round 1**: Sonnet + Specs A, B, C
- **Round 2**: Opus + Specs A, B, C
- **Round 3**: Haiku + Spec B

Score each 0–100. Log metrics to wan.db.

### Week 3: Analyze & Report
Compare outputs, extract findings, recommend approach for JikkoOps.

---

## 📅 Timeline

| Phase | Week | Activity | Leads |
|-------|------|----------|-------|
| **Planning** | 1 | Write 3 specs; get peer review | Diego |
| **Testing** | 2 | Run 7 Hermes tests; score outputs | Diego + Diana |
| **Analysis** | 3 | Compare results; write report | Diego + Javier |
| **Transition** | 4 | Wait for JikkoOps design finalization | (Gate) |
| **Application** | 5–6 | Apply to JikkoOps | Diego + colleague |
| **Implementation** | 7+ | Backend database work | Backend team |

---

## 👥 Team Roles

| Person | Role | Key Responsibilities |
|--------|------|----------------------|
| **Diego Trujillo** | Lead | Write specs, run tests, analyze |
| **Diana Plata** | Infrastructure | Set up Hermes, configure wan.db |
| **Juan David Lopez** | Mentor | Review specs, guide context engineering |
| **Javier Toquica** | Peer Review | Audit specs & SQL for best practices |

See `02_CONTRIBUTING.md` for detailed contribution guidelines.

---

## ✅ Success Checklist

**Week 1:**
- [ ] Picked problem domain (CEO approved)
- [ ] Wrote 3 specs (150/480/900 words)
- [ ] Got peer review ✅ approved
- [ ] Committed to Git

**Week 2:**
- [ ] Hermes setup complete
- [ ] 7 SQL outputs generated & validated
- [ ] All outputs scored (0–100)
- [ ] Metrics logged to wan.db

**Week 3:**
- [ ] Comparison matrix complete
- [ ] Key findings extracted
- [ ] Final report written
- [ ] Team consensus on approach

---

## 🛠️ Tools

- **Hermes** — LLM orchestrator gateway
- **Weights & Biases (wan.db)** — Metrics & observability
- **PostgreSQL** — Local test database
- **Git/GitHub** — Version control

---

## 📖 Next Steps

👉 **Read `01_QUICKSTART.md`** — Quick 5-minute onboarding  
👉 **Then read `01_planning/01_claude_md_to_hermes_strategy.md`** — Understand the philosophy  

Questions? Check the relevant README in your section or sync with your team lead.
