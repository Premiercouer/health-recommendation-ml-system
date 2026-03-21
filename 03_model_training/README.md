# 03 · Feature Engineering & Model Training

## Objective

Train 18 independent BigQuery ML models on the compressed label space
produced by `02_rule_engine_reverse`, and validate that the rule engine's
logic is fully reproducible through machine learning.

---

## Modeling Architecture

**Input features (16):** 8 difference indicators (`dif_*_mid`) + 8 current
value indicators (`c_val_*_mid`), all numeric midpoints shared across every model.

**18 independent BOOSTED_TREE_CLASSIFIER models**, split into two groups:

| Group | Models | Task | Labels |
|-------|--------|------|--------|
| Y1 — Tip models | 10 | Binary classification | 8 dimension tip groups + 2 Type C tips |
| Y2 — State models | 8 | Multi-class classification | `imp` / `acc` / `not` per dimension |

All 18 models share identical hyperparameters:

```sql
max_iterations = 40,  max_tree_depth = 4,
l2_reg = 1.0,         subsample = 0.8,
colsample_bytree = 0.8, early_stop = TRUE
```

See `sample_model_training.sql` for the full training template.

---

## Model Inventory

**Y1 — Tip models (binary)**

| Model | Label column | Type |
|-------|-------------|------|
| model_nutrition_tips | nutrition_tips | A |
| model_obesity_tips | obesity_tips | A |
| model_sleep_tips | sleep_tips | A |
| model_depression_tips | depression_tips | A |
| model_wellness_tips | wellness_tips | A |
| model_anti_stress_tips | anti_stress_tips | A |
| model_anti_smoke_tips | anti_smoke_tips | A |
| model_movement_tips | movement_tips | A |
| model_set_attainable_goals | `Set attainable goals` | C |
| model_dont_spend_too_much | `Don't spend too much` | C |

**Y2 — State models (multi-class)**

| Model | Label column |
|-------|-------------|
| model_nutrition_state | nutrition_state |
| model_obesity_state | obesity_state |
| model_sleep_state | sleep_state |
| model_depression_state | depression_state |
| model_wellness_state | wellness_state |
| model_anti_stress_state | anti_stress_state |
| model_anti_smoke_state | anti_smoke_state |
| model_movement_state | movement_state |

---

## Training Scale

| Metric | Value |
|--------|-------|
| Total slot time | ~124 days |
| Wall-clock runtime | ~12.5 hours |
| Data processed | ~22 TB |

---

## Performance Results

**Y1 — Tip models**

| Group | Precision | Recall | F1 | ROC AUC |
|-------|-----------|--------|----|---------|
| Type A tip models (8) | 0.997 | 0.990 | 0.993 | 1.000 |
| Type C tip models (2) | 0.680 | 0.294 | 0.410 | 0.845 |

**Y2 — State models (8)**

| Precision | Recall | F1 | ROC AUC |
|-----------|--------|----|---------|
| 1.000 | 1.000 | 1.000 | 1.000 |

**Why Type C models underperform**

The two Type C tips (`Set attainable goals`, `Don't spend too much`) are
jointly controlled by two dimensions and participate in the same random
sampling process as Type A tips. Because identical inputs can produce
different outputs depending on which tips the engine selects, the label
is non-deterministic by design. No supervised model can learn a perfectly
consistent mapping under this condition — the performance ceiling is set
by the engine itself, not by the model.

---

## Files

| File | Description |
|------|-------------|
| `sample_model_training.sql` | Representative training template for all 18 models; only the label column varies per model |
