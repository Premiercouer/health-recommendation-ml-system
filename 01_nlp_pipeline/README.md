# 01 · NLP Pipeline — Structured Label Construction

## Objective

Transform the free-text output columns of the 429M-row dataset into a
structured, training-ready table (`train_ready`) consumed by all downstream
steps. The pipeline handles two distinct NLP tasks:

- **Recommendation text** → 33 binary tip presence flags (Y1)
- **Status assessment text** → 24 three-state dimension labels (Y2)

---

## Pipeline Overview

```
BigQuery SQL                      Workbench (Python)              BigQuery SQL
────────────────────────────────  ──────────────────────────────  ──────────────────────────────
01_extract_base_tips_raw.sql  →   Extract_base_tips.ipynb     →   build train_ready
Split recommendations on '.'      Repair fragment edge cases       Midpoint-encode 16 features
429M rows → 76 raw candidates     Deduplicate → 37 tips            One-hot encode 33 tips  (Y1)
                                  Merge fragments → 33 tips        Parse status text → 24 labels (Y2)
                                  Write base_tips_final.csv        Output: train_ready (73 cols)
```

---

## Why Two Stages for Tip Extraction

BigQuery handles the 429M-row scale, but splitting on `.` produces malformed
fragments that require Python-level repair. Two recurring breakage patterns:

- **`ex. walking`** — an in-sentence abbreviation that BigQuery misreads as a
  sentence boundary, producing a dangling `(ex` fragment and an orphaned
  `walking)` prefix
- **`They can keep you accountable!`** — a sentence that appears fused with
  the following tip after reassembly

Five edge-case rules in `Extract_base_tips.ipynb` resolve these, reducing
76 raw candidates → 37 cleaned tips → 33 final base tips after semantic merging.

---

## Label Design

**Y1 — One-hot tip encoding**

Each of the 33 base tips is matched against the `recommendations` text using
a unique anchor string:

```sql
CASE WHEN recommendations LIKE '%Set attainable goals%' THEN 1 ELSE 0 END AS rec_1,
CASE WHEN recommendations LIKE '%Tell your family%'     THEN 1 ELSE 0 END AS rec_2,
-- ... repeated for all 33 tips
```

**Y2 — Three-state status labels**

`status_assessment` is parsed with two regex extractions to identify which
dimensions are flagged as needing improvement (`imp`) or at an acceptable
level (`acc`). A third state (`not`) is derived when neither applies:

```sql
COALESCE(REGEXP_EXTRACT(status_assessment, r'improving with respect to your ([^.]+)\.'), '') AS imp_part,
COALESCE(REGEXP_EXTRACT(status_assessment, r'acceptable level for ([^.]+)\.'),           '') AS acc_part
```

This produces 3 mutually exclusive columns per dimension (e.g.
`obesity_imp`, `obesity_acc`, `obesity_not`), 24 columns across 8 dimensions.

**Feature encoding**

Input range strings are mapped to numeric midpoints so all labels share one
consistent feature space:

```sql
CASE dif_nutrition
  WHEN '0-250'          THEN  125.0
  WHEN '250-1000'       THEN  625.0
  WHEN '(-1000)-(-250)' THEN -625.0
  WHEN '(-250)-0'       THEN -125.0
END AS dif_nutrition_mid
```

This pattern applies uniformly across all 8 dimensions (16 feature columns total).

---

## Output

`train_ready` — 73 columns, stored in BigQuery:

| Group    | Columns | Description |
|----------|---------|-------------|
| Features | 16      | Numeric midpoints (`dif_*_mid`, `c_val_*_mid`) |
| Y1       | 33      | One-hot tip flags (`rec_1` … `rec_33`) |
| Y2       | 24      | Three-state status per dimension (`{dim}_imp/acc/not`) |

Consumed by → `02_rule_engine_reverse` and `03_feature_engineering`

---

## Files

| File | Platform | Description |
|------|----------|-------------|
| `01_extract_base_tips_raw.sql` | BigQuery | Splits recommendation text and extracts 76 distinct raw tip candidates |
| `Extract_base_tips.ipynb` | Vertex AI Workbench | Repairs fragmented sentences and produces 33 standardized base tips |
