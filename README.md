# Health Recommendation ML System

A production-scale machine learning system that reverse-engineers a proprietary
health recommendation engine and reproduces its logic through BigQuery ML,
processing 429 million records (331 GB) across 8 health dimensions.

> **Phase 1 — Exploratory Analysis (746k rows):**
> Rule discovery, NLP pipeline, and model prototyping conducted on a partial
> dataset are documented in the companion repository:
> [health-recommendation-engine-analysis](https://github.com/Premiercouer/health-recommendation-engine-analysis)
>
> This repository covers Phase 2: scaling the validated findings to the full
> input space and deploying an end-to-end inference system.

---

## Project Overview

The sponsor operates a health recommendation engine that maps patient health
indicators to personalized text advice. The engine's internal rule logic was
undocumented and unreproducible. This project reverse-engineers that logic at
scale and delivers a standalone system that replicates its behaviour.

**The core challenge:** the engine outputs free-form text with no visibility
into its trigger conditions. Reconstructing the logic required a four-stage
pipeline — from NLP-based label construction, through rule classification, to
model training and inference deployment.

---

## Architecture

```
429M-row dataset (BigQuery, 331 GB)
        │
        ▼
┌─────────────────────┐
│  01 · NLP Pipeline  │  Extract 33 base tips · Encode 57 structured labels
└──────────┬──────────┘
           │
           ▼
┌───────────────────────────────┐
│  02 · Rule Engine Reverse     │  Frequency-variance framework · ABCD classification
│                               │  Label compression: 33 tips → 10 targets
└──────────┬────────────────────┘
           │
           ▼
┌───────────────────────────────┐
│  03 · Feature Eng. & Modeling │  18 BigQuery ML models · 22 TB processed · ~12.5h runtime
└──────────┬────────────────────┘
           │
           ▼
┌───────────────────────────────┐
│  04 · Inference Pipeline      │  predict.py · JSON in → health advice out
└───────────────────────────────┘
```

---

## Technical Highlights

**Large-scale data processing on GCP**
The full combinatorial input space of the rule engine spans 429M rows (331 GB),
stored and processed entirely in BigQuery. All feature engineering, label
construction, and model training run as BigQuery SQL jobs — no data movement,
no local compute bottleneck. Training 18 models processed ~22 TB of data in
~12.5 hours of wall-clock time.

**Rule Engine Reverse Engineering**
With no access to the engine's source code, the rule trigger logic was
reconstructed from output text alone. A frequency-variance framework measured
how each tip's appearance rate varied across health dimension input ranges —
high variance signals causal control. This produced a full ABCD classification
of all 33 base tips, mapping each to its controlling dimension(s).

**Feature engineering from rule structure**
The ABCD classification directly informed the label design. Analysis of the
sleep dimension revealed that the engine randomly samples 2 tips per dimension
rather than outputting all of them — making direct per-tip prediction
unlearnable. Grouping tips by their controlling dimension and applying
OR-aggregation resolved this, transforming stochastic outputs into stable
prediction targets and delivering a **+68% improvement in model precision**.

**BigQuery ML at scale**
18 independent `BOOSTED_TREE_CLASSIFIER` models were trained natively in
BigQuery ML, eliminating data export and leveraging BigQuery's distributed
compute. Models are stored in BigQuery and called directly via `ML.PREDICT`
at inference time — no model serving infrastructure required.

**Cost-optimised NLP pipeline**
Extracting and standardizing 33 base tips from 429M rows of free-form text
was split across two platforms by design: BigQuery SQL handled the volume
(sentence splitting and deduplication at scale), while Vertex AI Workbench
handled the precision (fragment repair and semantic merging in Python).
Running the full NLP workload in Workbench would have been significantly
more expensive and slower.

**End-to-end inference pipeline**
`predict.py` connects raw health indicator JSON to natural language output
in a single script — range encoding, BigQuery `ML.PREDICT` across 18 models,
and natural language decoding — with no dependencies beyond the BigQuery
Python client.

---

## Repository Structure

```
├── 01_nlp_pipeline/                   # NLP label construction
│   ├── 01_extract_base_tips_raw.sql
│   └── Extract_base_tips.ipynb
│
├── 02_rule_engine_reverse/            # Rule attribution & label compression
│   ├── 01_compute_tip_frequency.sql
│   ├── 02_variance_abtype.sql
│   ├── 03_abcd_classification.sql
│   └── 04_regroup_labels.sql
│
├── 03_feature_engineering_modeling/   # BigQuery ML model training
│   └── sample_model_training.sql
│
├── 04_inference_pipeline/             # End-to-end prediction system
│   ├── predict.py
│   ├── input.json
│   └── output.json
│
├── requirements.txt
└── .gitignore
```

---

## Tech Stack

| Layer | Tools |
|-------|-------|
| Data & SQL | BigQuery, BigQuery ML |
| NLP & Preprocessing | Python, pandas, regex |
| Model Training | BigQuery ML `BOOSTED_TREE_CLASSIFIER` |
| Inference | Python, `google-cloud-bigquery` |
| Storage | Google Cloud Storage |
| Execution Environment | Vertex AI Workbench, GCP Dataproc |

---

## Setup

```bash
pip install -r requirements.txt
```

Requires a GCP project with BigQuery access and Application Default Credentials:

```bash
gcloud auth application-default login
```

To run inference:

```bash
cd 04_inference_pipeline
python predict.py
```
