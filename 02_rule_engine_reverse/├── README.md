# 02 · Rule Engine Reverse Engineering

## Objective

Identify which health dimensions control each of the 33 base tips, and
classify every tip into one of four behavioral types (ABCD). The resulting
classification directly determines the label compression strategy in
`03_feature_engineering`.

---

## Method

The core insight is that if a tip is controlled by a dimension, its appearance
rate should vary significantly across that dimension's input ranges. This is
operationalized through a **frequency-variance framework**:

1. Compute the appearance frequency of each tip across every input range of every dimension
2. Measure the variance of that frequency — high variance signals dimension influence
3. For each influential (dimension, tip) pair, characterize the relationship as Type A or B based on baseline frequency
4. Aggregate per-tip A/B counts to assign the final ABCD label

---

## ABCD Classification

| Type | Definition | Count |
|------|-----------|-------|
| A | Activated exclusively in the high-risk range of one dimension; near-zero baseline | 31 |
| B | Elevated in the high-risk range of one dimension, but present at baseline | 0 |
| C | Jointly controlled by two or more dimensions | 2 |
| D | Near-constant appearance rate; not controlled by any dimension | 0 |

**Key finding:** Running the same classification on the complete input space
(vs. the partial 746k sample used in Phase 1) revealed that Type B and Type D
tips disappear entirely, and two genuine Type C tips emerge. This happened
because the partial dataset held obesity permanently in a high-risk state,
masking multi-dimension coupling effects. The complete dataset exposes the
true rule structure.

---

## Why Grouping — Not Direct Tip Prediction

Analysis of the sleep dimension revealed a critical property of the rule
engine: even when a dimension enters a high-risk range, its associated tips
are **not all output simultaneously**. Instead, the engine randomly selects
two tips from that dimension's candidate pool.

This means the same input state can produce different tip combinations across
rows — identical feature vectors map to different labels. A model trained to
predict individual tips directly cannot learn a consistent mapping under this
condition, because the non-determinism is inherent to the engine, not noise
in the data.

The solution is to **group tips by their controlling dimension** and predict
group activation instead of individual tip presence. If any tip in a
dimension's pool appears, the group label is 1 (OR-aggregation). This
transforms stochastic per-tip outputs into a stable, learnable signal.

This single design decision was the primary driver of model improvement:
compressing 33 individual tip labels into 10 grouped prediction targets
led to a **precision improvement of +0.4** in the subsequent modeling step.
Details of the final model performance are covered in `03_feature_engineering`.

---

## Label Compression: 33 Tips → 10 Prediction Targets

The ABCD classification maps directly to the grouping strategy:

- **31 Type A tips** — grouped by their controlling dimension (8 groups),
  OR-aggregated: `GREATEST(rec_i, rec_j, ...) AS {dim}_tips`
- **2 Type C tips** — cross-dimension; kept as independent binary labels
  since they cannot be assigned to a single dimension group

This yields 10 compressed prediction targets passed to `03_feature_engineering`.

---

## Files

Run in order:

| Step | File | Output Table | Description |
|------|------|-------------|-------------|
| 1 | `01_compute_tip_frequency.sql` | `tip_freq_by_dim_range` | UNPIVOT all 33 tips × 8 dimensions; compute appearance frequency per (dim, range) |
| 2 | `02_variance_abtype.sql` | `tip_ab_typed` | Fill zero-frequency gaps, compute variance per (dim, tip), assign A/B type |
| 3 | `03_abcd_classification.sql` | `tip_abcd_classification` | Aggregate A/B counts into final ABCD labels; add global frequency for Type D detection |
| 4 | `04_regroup_labels.sql` | `train_ready_v2` | Compress 33 individual tip labels into 10 grouped targets: 8 dimension groups (GREATEST OR-logic over Type A tips) + 2 standalone Type C labels |
