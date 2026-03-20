# 01 · NLP Pipeline — Base Tip Extraction

## Objective

Extract and standardize the atomic recommendation sentences (base tips) embedded in the free-text `recommendations` column of the 429M-row dataset. The output is a clean set of 33 base tips used as the prediction targets for downstream modeling.

## Why Two Stages

The extraction is split across two platforms for a practical reason: BigQuery handles the scale (429M rows), but its SQL-based sentence splitting produces malformed fragments that require Python-level text repair.

Specifically, splitting on `.` causes two recurring breakage patterns:
- `ex. walking` — an in-sentence abbreviation that BigQuery misreads as a sentence boundary, producing a dangling `(ex` fragment and an orphaned `walking)` prefix
- `They can keep you accountable!` — a sentence that appears fused with the following tip after reassembly

These cases are not cleanly fixable in SQL, which motivates the Workbench step.

## Pipeline

```
BigQuery SQL                        Workbench (Python)
────────────────────────────────    ──────────────────────────────────
SPLIT recommendations on '.'   →    Repair 5 fragment edge cases
UNNEST + DISTINCT + TRIM            Strip trailing punctuation
429M rows → 76 raw candidates  →    Deduplicate → 37 tips
Export CSV to GCS               →    Merge semantically split tips
                                     37 → 33 final base tips → GCS
```

## Files

| File | Platform | Description |
|------|----------|-------------|
| `extract_base_tips_raw.sql` | BigQuery | Splits and deduplicates recommendation text; produces 76 raw candidate sentences |
| `Extract_base_tips.ipynb` | Vertex AI Workbench | Repairs fragmented sentences, deduplicates, and merges semantically related tips into 33 standardized base tips |

## Output

`base_tips_final.csv` — 33 standardized base tips, stored in GCS, used as the recommendation label space in `02_rule_engine_reverse` and `03_feature_engineering`.
