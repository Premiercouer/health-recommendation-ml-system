-- ============================================================
-- 04_regroup_labels.sql
-- Compresses 33 individual tip labels into 10 grouped prediction
-- targets based on the ABCD classification from step 3.
--
-- Grouping strategy:
--   Type A (31 tips): OR-aggregated by controlling dimension.
--     GREATEST(rec_i, rec_j, ...) = 1 if any tip in the group fires.
--   Type C (2 tips): cross-dimension; kept as independent labels.
--
-- This compression resolves the internal randomness of the rule
-- engine (which samples 2 tips per dimension rather than outputting
-- all), transforming stochastic per-tip targets into stable,
-- learnable group-level signals.
--
-- Reads from: train_ready
-- Output:     train_ready_v2
-- ============================================================

CREATE OR REPLACE TABLE `northeastgroup4t.health_dataset_generation.train_ready_v2` AS

SELECT
  -- ── 16 feature columns ───────────────────────────────────────
  dif_nutrition_mid,   dif_obesity_mid,    dif_sleep_mid,      dif_depression_mid,
  dif_wellness_mid,    dif_anti_stress_mid,dif_anti_smoke_mid, dif_movement_mid,
  c_val_nutrition_mid, c_val_obesity_mid,  c_val_sleep_mid,    c_val_depression_mid,
  c_val_wellness_mid,  c_val_anti_stress_mid, c_val_anti_smoke_mid, c_val_movement_mid,

  -- ── 10 compressed label columns (Y1) ─────────────────────────
  -- Type A: one label per dimension, fires if any tip in the group appears
  GREATEST(rec_10, rec_24, rec_30)                       AS nutrition_tips,
  GREATEST(rec_15, rec_28, rec_32)                       AS obesity_tips,
  GREATEST(rec_17, rec_23, rec_31)                       AS sleep_tips,
  GREATEST(rec_11, rec_18, rec_25, rec_33, rec_6)        AS depression_tips,
  GREATEST(rec_12, rec_13, rec_4)                        AS wellness_tips,
  GREATEST(rec_16, rec_26, rec_27, rec_5, rec_7)         AS anti_stress_tips,
  GREATEST(rec_14, rec_19, rec_2,  rec_22, rec_3, rec_8) AS anti_smoke_tips,
  GREATEST(rec_20, rec_21, rec_9)                        AS movement_tips,

  -- Type C: cross-dimension tips, not assignable to a single group
  rec_1  AS rec_set_attainable_goals,
  rec_29 AS rec_dont_spend_too_much,

  -- ── 24 Y2 label columns ──────────────────────────────────────
  nutrition_imp,   nutrition_acc,   nutrition_not,
  obesity_imp,     obesity_acc,     obesity_not,
  sleep_imp,       sleep_acc,       sleep_not,
  depression_imp,  depression_acc,  depression_not,
  wellness_imp,    wellness_acc,    wellness_not,
  anti_stress_imp, anti_stress_acc, anti_stress_not,
  anti_smoke_imp,  anti_smoke_acc,  anti_smoke_not,
  movement_imp,    movement_acc,    movement_not

FROM `northeastgroup4t.health_dataset_generation.train_ready`;
