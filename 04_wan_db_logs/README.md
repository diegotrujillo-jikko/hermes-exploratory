# Weights & Biases (wan.db) Logs

This directory contains **metrics, scores, and observability data** from your Hermes tests tracked in Weights & Biases.

## Overview

wan.db (Weights & Biases) is your observability layer. It records:

- Quality score for each SQL output (0–100, using the rubric)
- Per-category breakdown (structure, naming, integrity, comments, feasibility, spec adherence)
- Model choice, spec variant, and test round
- Cost metrics (tokens used, time to generate)
- Qualitative notes and observations

This enables **statistical comparison** instead of guesswork.

## File Structure

### Summary Files

- **`round_1_metrics.json`** — Sonnet + varying specs (Specs A, B, C)
- **`round_2_metrics.json`** — Opus + varying specs (Specs A, B, C)
- **`round_3_metrics.json`** — Multiple models + Spec B (Sonnet, Opus, Haiku)

### Example Metric Entry (JSON)

```json
{
  "test_id": "round_1_sonnet_spec_a",
  "timestamp": "2026-05-20T14:30:00Z",
  "round": 1,
  "model": "sonnet",
  "spec_variant": "a",
  "spec_words": 150,
  "output_file": "outputs/round_1_sonnet_spec_a.sql",
  
  "quality_score": 75,
  "score_breakdown": {
    "structure": 28,          // out of 30
    "naming": 12,             // out of 15
    "integrity": 16,          // out of 20
    "comments": 10,           // out of 15
    "query_feasibility": 7,   // out of 10
    "spec_adherence": 2       // out of 10
  },
  
  "observations": {
    "hallucinated_columns": ["metadata", "tags"],
    "missing_tables": [],
    "missing_constraints": ["UNIQUE on email"],
    "naming_issues": ["used camelCase in order_status instead of order_state"],
    "positive": "Excellent structure; all core relationships present"
  },
  
  "cost_metrics": {
    "tokens_input": 1250,
    "tokens_output": 450,
    "tokens_total": 1700,
    "generation_time_seconds": 8.3
  },
  
  "notes": "Solid baseline. Minimal spec left gaps in constraint definition."
}
```

## How to Log Metrics

### Manual Entry (If Not Using Weights & Biases Dashboard)

1. After generating SQL, score it using `planning/QUALITY_RUBRIC.md`
2. Create a JSON entry like above
3. Save to this directory as `round_[N]_metrics.json`
4. Later sync to Weights & Biases dashboard with: `wandb sync`

### Using Weights & Biases CLI

```bash
# Install wandb (if not already installed)
pip install wandb

# Initialize a wandb project
wandb init

# Log a run programmatically
wandb.log({
    "test_id": "round_1_sonnet_spec_a",
    "quality_score": 75,
    "structure": 28,
    "naming": 12,
    "integrity": 16,
    "comments": 10,
    "query_feasibility": 7,
    "spec_adherence": 2
})
```

## Key Metrics to Track

For each of 7 runs, capture:

| Metric | Why It Matters |
|--------|---|
| **quality_score** (0–100) | Overall output quality; your main comparison axis |
| **structure** (category score) | Are tables & relationships correct? |
| **naming** (category score) | Are naming conventions followed? |
| **integrity** (category score) | Are constraints appropriate? |
| **comments** (category score) | Is design documented? |
| **query_feasibility** (category score) | Can you actually query this? |
| **spec_adherence** (category score) | Did model follow your spec or hallucinate? |
| **tokens_total** | Cost metric (higher = more expensive) |
| **generation_time_seconds** | Speed metric (lower = faster) |
| **hallucinated_columns** | How many non-spec columns were added? |
| **observations** | Qualitative notes for later analysis |

## Comparison Matrix

Once you have all 7 runs logged, create a summary CSV or table:

```csv
test_id,round,model,spec,spec_words,quality_score,structure,naming,integrity,comments,query_feasibility,spec_adherence,tokens,time_sec
round_1_sonnet_spec_a,1,sonnet,a,150,75,28,12,16,10,7,2,1700,8.3
round_1_sonnet_spec_b,1,sonnet,b,480,92,30,14,19,12,9,8,2100,9.1
round_1_sonnet_spec_c,1,sonnet,c,900,95,30,15,20,13,9,8,2400,10.2
round_2_opus_spec_a,2,opus,a,150,88,29,14,18,11,8,8,1800,8.8
round_2_opus_spec_b,2,opus,b,480,92,30,14,19,12,9,8,2200,9.5
round_2_opus_spec_c,2,opus,c,900,96,30,15,20,13,10,8,2500,10.5
round_3_haiku_spec_b,3,haiku,b,480,78,26,11,15,9,7,3,1400,7.2
```

## Analysis Patterns

Look for:

1. **Spec Depth Impact** (Round 1 data)
   - Does Spec B (480 words) get 90%+ of Spec C (900 words) quality?
   - Diminishing return = (Score_C - Score_B) / (Score_B - Score_A)

2. **Model Differences** (Round 2 vs. Round 1)
   - Does Opus consistently score higher than Sonnet?
   - By how much?

3. **Model-Spec Fit** (Round 3 data)
   - Which model + spec combo is best?
   - Cost-to-quality ratio: score / tokens_total

4. **Consistency**
   - Is Sonnet consistent across runs? (low variance = reliable)
   - Is Opus more thorough but slower? (higher score, more tokens)

## Syncing to Cloud

Once you're ready to share metrics or visualize in wandb dashboard:

```bash
# One-time: Log in to wandb
wandb login

# Before pushing to Git, export local logs
wandb sync --project="hermes-exploratory"

# View dashboard
# Go to: https://wandb.ai/[your-username]/hermes-exploratory
```

## Version Control

✅ **DO commit** `round_N_metrics.json` files (they're small, important for analysis)

✅ **DO commit** `.csv` comparison matrices (readable, lightweight)

❌ **DON'T commit** full wandb logs (they're large; `.gitignore` handles `wandb/`)

---

**See also:**
- `planning/QUALITY_RUBRIC.md` — How to score each output
- `outputs/README.md` — Where the SQL files live
- `analysis/README.md` — How to compare & analyze results
