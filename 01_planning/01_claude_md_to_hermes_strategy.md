# CLAUDE.md Best Practices → Hermes/wan.db Exploratory Phase

## Part 1: CLAUDE.md Best Practices (from Nick's Video)

### The 10 Key Sections for CLAUDE.md Files

Nick identifies these sections as essential for Claude Code to operate effectively:

| # | Section | Purpose | Impact |
|---|---------|---------|--------|
| 1 | **Project Overview** | Explain what it is, who it's for, business constraints | Highest value; creates foundational context |
| 2 | **Tech Stack** | Specific technologies, what NOT to use | Prevents technically valid but wrong library choices |
| 3 | **Architecture** | Directory structure, responsibilities, data flow | Teaches Claude where new code belongs |
| 4 | **Coding Conventions** | Day-to-day code generation rules | 2nd most important; direct quality impact |
| 5 | **UI/Design System Rules** | Visual styles, spacing, typography, patterns | Pure gold for frontend; prevents design drift |
| 6 | **Content Guidance** | Copy tone (concise/detailed, technical/plain) | Critical for UX/product work |
| 7 | **Testing & Quality Bar** | Tests required, definitions of done | Clarifies validation expectations |
| 8 | **File & Content Placement** | When to create vs. edit, naming patterns | Prevents duplicate components in mature repos |
| 9 | **Safe Change Rules** | What Claude should avoid changing casually | Reduces operationally risky refactorings |
| 10 | **Specific Commands** | Real, current CLI commands the system uses | Operational context; must be accurate |

**Critical Constraints:**
- Keep CLAUDE.md **under 200 lines** (scannable, human-readable)
- Use `/init` command as starting point, then **refine aggressively**
- Treat generated files as "first draft only" — gaps will exist

---

## Part 2: How This Maps to Your Hermes/wan.db Strategy

### The Core Insight from Your Sync AI Meeting

Your CEO and Juan David are teaching the team a principle: **context engineering is the new discipline**.

Compare:

| CLAUDE.md Philosophy | Hermes/wan.db Philosophy |
|----------------------|--------------------------|
| Specification guides Claude Code's behavior | Detailed specs guide Hermes-orchestrated models' behavior |
| Without clear architecture rules, Claude makes wrong assumptions | Without clear context specs, LLMs hallucinate |
| Coding conventions ensure consistent output quality | Different specs + fixed model = measurable quality variance |
| Safe change rules prevent risky refactors | Context filtering reduces noise, improves precision |

**Key Quote from Meeting:** 
> "Ingeniería de contexto" (context engineering) is not just prompts—it's detailed specifications in Markdown format combined with visual prototypes. Context defines the statistical probability of correct output.

### The wan.db Role: Observability of Specifications

Weights & Biases (wan.db) does for **context specs** what unit tests do for code:

- **Fixed Model + Varying Specs** → measure which spec produces best output
- **Fixed Spec + Varying Models** → measure which model understands your domain best
- **Result**: Statistical confidence in "which combination works"

This is what Juan David ran: testing Sonnet, Opus, ChatGPT, Gemini with the same specification to prove Sonnet was best for MVP simplicity and Opus best for depth/security.

---

## Part 3: Your Exploratory Phase Strategy

### What You Should NOT Do

❌ **Don't jump straight to JikkoOps testing**
- Design team is still iterating; data model not finalized
- Too complex as a first experiment; too much risk if something breaks
- CEO explicitly said "exploratory phase" ≠ JikkoOps implementation

❌ **Don't treat this as "just installing tools"**
- Hermes + wan.db are teaching instruments, not commodities
- The learning is in *how context specs affect output*, not in running commands

### What You SHOULD Do: A Bounded Exploratory Phase

**Goal**: Demonstrate that context engineering + Hermes orchestration + wan.db observability actually improves output quality. Use a small, real but separate domain.

#### Phase Structure (2–3 week cycle)

**Week 1: Specification Design**

1. **Pick a small, bounded problem** (NOT JikkoOps; something real but simpler)
   - Example: *Design a database schema for a simple order management system* (10–15 tables)
   - OR: *Define API endpoints for a user authentication module*
   - Criteria: 
     - Achievable in 2–3 hours of manual modeling
     - Has 3–4 distinct decision points where different specs might diverge
     - Related enough to JikkoOps philosophy (operational systems) to transfer learning

2. **Create 3 different CLAUDE.md-style specifications** for the same problem
   - **Spec A (Minimal)**: Project overview + tech stack only (200 words)
   - **Spec B (Balanced)**: Project overview + tech stack + architecture + coding conventions (500 words)
   - **Spec C (Comprehensive)**: All 10 sections from Nick's guide (800–1000 words)
   - **Key:** Identical problem statement, different context depth

**Week 2: Hermes Orchestration & Observability**

3. **Set up Hermes locally** with 2–3 models (e.g., Sonnet, Opus, Claude Haiku)
   
4. **Run 3 rounds of tests via Hermes:**
   - **Test Round 1**: Fix Sonnet, feed Specs A, B, C → measure output quality
   - **Test Round 2**: Fix Opus, feed Specs A, B, C → measure output quality
   - **Test Round 3**: Fix Spec B, feed Sonnet, Opus, Haiku → measure model performance with balanced context

5. **Measure using wan.db metrics:**
   - **Spec Quality**: Does the spec reduce hallucination? (% of proposed tables/endpoints that match constraints)
   - **Model Efficiency**: Which model best understood the spec? (accuracy, depth, risk identification)
   - **Context Variance**: Is there a diminishing return beyond Spec B? (more context = better output, or noise?)

**Week 3: Analysis & Artifacts**

6. **Consolidate results:**
   - Which spec depth + which model combo performed best?
   - How much did spec detail matter vs. model choice?
   - What content in Specs A, B, C was actually used by the models?

7. **Document findings:**
   - Update CLAUDE.md best practices based on *your data*
   - Create a `HERMES_CONTEXT_GUIDE.md` for your team's Hermes deployment
   - Capture Hermes + wan.db workflow as a reusable template

---

## Part 4: Relationship to JikkoOps

### Should You Include JikkoOps in the Exploratory Phase?

**Short Answer: No, but yes—structurally.**

**Reasoning:**

1. **Not directly**: Don't run your exploratory problem ON JikkoOps data/context
   - Too risky; design is still changing
   - Using unfinalized design as ground truth skews results
   - You'd be testing "is our context good?" on a moving target

2. **But structurally**: Apply what you learn to JikkoOps *preparation*
   - Once design team finalizes JikkoOps prototype (your blocking milestone)
   - You'll have a **data-backed methodology** for translating design → schema
   - Use Hermes + wan.db to test different data modeling specs against JikkoOps requirements
   - Only then finalize the database

3. **Timeline**:
   ```
   Week 1–3:   Exploratory phase (order mgmt or auth system) + learn Hermes/wan.db
   Week 4:     Design team finalizes JikkoOps prototype (your input gate)
   Week 5–6:   Apply exploratory methodology to JikkoOps data model
   Week 7+:    You and colleague deliver refined schema to backend
   ```

---

## Part 5: Actionable Next Steps

### Immediate (This Week)

1. **Finalize your small problem** for exploration
   - Get CEO/PM alignment (5 min conversation)
   - Confirm it's scoped enough to do specs + testing in 2 weeks
   - Ensure it's "real" enough to transfer learning to JikkoOps

2. **Sketch your 3 CLAUDE.md variants** using Nick's 10-section framework
   - Don't write full specs yet; outline structure
   - Identify which sections differ between Spec A, B, C
   - Share with Juan David or CEO for feedback

3. **Set up Hermes + wan.db locally** (Diana's doing this; coordinate)
   - Install Hermes, connect to Anthropic API
   - Set up wan.db offline tracking (before cloud sync)
   - Test with a dummy run (no actual specs yet)

### Week 1–2

4. **Write your 3 specs** in markdown
   - Use Nick's structure as skeleton
   - Keep under 200 lines each (follow the rule)
   - Get peer review from Javier or team before testing

5. **Run Hermes orchestration** with fixed model + varying specs
   - Document each run in wan.db
   - Capture output quality metrics (consistency, correctness, depth)

6. **Switch: fixed spec + varying models**
   - Same problem, same Spec B context
   - Run Sonnet, Opus, Haiku in parallel via Hermes
   - Compare results in wan.db

### Week 3

7. **Analyze & document** findings
   - What spec depth was "sufficient"?
   - Which model understood your domain best?
   - How much does context engineering matter for *your use case*?

8. **Create a HERMES_METHODOLOGY.md** for Jikkosoft
   - Your team's approach to context specs for Hermes
   - Template for future exploratory phases
   - Lessons learned

---

## Part 6: Key Questions to Solve During Exploration

By the end of Week 3, you should be able to answer these definitively:

1. **Specification Impact**: Does a 500-word spec (Spec B) produce 80%+ the quality of a 1000-word spec (Spec C)?
   - If yes → use Spec B depth as your standard for JikkoOps
   - If no → invest the time in comprehensive specs

2. **Model Fit**: Which model (Sonnet, Opus, Haiku) best understands your domain-specific constraints?
   - Sonnet = good for simplicity + speed (MVP preference)
   - Opus = good for depth + security (risk identification)
   - Haiku = good for cost, acceptable quality?

3. **Noise vs. Signal**: How much does irrelevant context hurt output?
   - Include some "noise" in one spec variant
   - Measure if wan.db shows degradation
   - Informs how to curate context for JikkoOps

4. **Hermes Overhead**: Is Hermes orchestration + wan.db measurement adding value, or just complexity?
   - Single model + detailed spec = sufficient?
   - Or does multi-model orchestration + observability justify the setup?

---

## Summary: Your Role This Month

| Week | What | Why | Output |
|------|------|-----|--------|
| 1–3 | Exploratory phase (bounded problem) | Prove context engineering methodology works | Metrics, analysis, HERMES_METHODOLOGY.md |
| 4 | Wait for design finalization | Can't test on moving target | (Input gate for data modeling) |
| 5–6 | Apply to JikkoOps specs | Use proven methodology | Schema options, context-derived model |
| 7+ | Deliver refined DB schema | Backend-ready, CEO-approved | Production-ready DDL |

**The CEO's Logic:**
"Before building JikkoOps backend (risky, complex, must be right), let's learn how Hermes + wan.db work on a smaller problem. Then we apply that confidence to the actual system."

It makes sense. Do the small experiment first. ✓

