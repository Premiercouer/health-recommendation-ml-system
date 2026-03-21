# 04 · Inference Pipeline

## Objective

Combine all 18 trained models into a single end-to-end prediction system.
Given a user's raw health indicators as input, the pipeline produces a
natural language health assessment and personalized recommendations as output.

---

## Pipeline

```
input.json
    │
    ▼
┌─────────────────────────────────────────────────────┐
│  Preprocessing (predict.py)                         │
│  Map raw values to midpoints → 16-dim feature vector│
└─────────────────────────────┬───────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────┐
│  Model Inference (BigQuery ML)                      │
│  ML.PREDICT × 18 models                             │
│  ├─ 10 tip models  → binary predictions (0 / 1)     │
│  └─ 8 state models → class predictions (imp/acc/not)│
└─────────────────────────────┬───────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────┐
│  Natural Language Decoding (predict.py)             │
│  ├─ State predictions → status_assessment text      │
│  └─ Tip predictions   → recommendations text        │
│     ├─ Type A: random.sample(pool, 2) per dimension │
│     └─ Type C: fixed sentence mapping               │
└─────────────────────────────┬───────────────────────┘
                              │
                              ▼
output.json
```

---

## Decoding Logic

**Status assessment** is reconstructed from the 8 state model outputs by
collecting dimensions into `imp` and `acc` buckets and formatting them into
a natural language sentence:

```python
if imp_dims:
    "You need to start improving with respect to your {dims}."
if acc_dims:
    "In the long term, you may still be at the risk of {dims}."
```

**Recommendations** are assembled in two passes:
- **Type A tips**: for each active dimension group, 2 sentences are randomly
  sampled from the pool — replicating the rule engine's internal sampling behaviour
- **Type C tips**: directly mapped to a fixed sentence when the model predicts 1

---

## Usage

```bash
python predict.py
```

Reads `input.json`, writes predictions to `output.json`.

**Input format** (`input.json`) — 16 raw health indicators:

```json
{
  "id": "user_001",
  "dif_nutrition": 10,
  "c_val_nutrition": 520,
  ...
}
```

**Output format** (`output.json`):

```json
{
  "id": "user_001",
  "input": { ... },
  "status_assessment": "Be careful! You need to start improving with respect to your Depression, Movement and Obesity. In the long term, you may still be at the risk of Anti-Stress.",
  "recommendations": "Restrict the intake of sugars-sweetened soft drinks. ..."
}
```

---

## Files

| File | Description |
|------|-------------|
| `predict.py` | Full pipeline: preprocessing → BigQuery ML inference × 18 → NL decoding |
| `input.json` | Sample input with 16 health indicators |
| `output.json` | Sample output with generated status assessment and recommendations |
