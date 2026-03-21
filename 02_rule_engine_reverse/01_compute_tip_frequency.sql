-- ============================================================
-- 01_compute_tip_frequency.sql
-- For each (dimension × input range × tip), compute the
-- percentage of rows in which that tip appears.
-- Output: tip_freq_by_dim_range
-- ============================================================

CREATE OR REPLACE TABLE
  `northeastgroup4t.health_dataset_generation.tip_freq_by_dim_range`
AS

WITH all_tips AS (
  SELECT tip
  FROM UNNEST([
    'rec_1','rec_2','rec_3','rec_4','rec_5','rec_6','rec_7','rec_8','rec_9','rec_10',
    'rec_11','rec_12','rec_13','rec_14','rec_15','rec_16','rec_17','rec_18','rec_19','rec_20',
    'rec_21','rec_22','rec_23','rec_24','rec_25','rec_26','rec_27','rec_28','rec_29','rec_30',
    'rec_31','rec_32','rec_33'
  ]) AS tip
),

-- STEP 1: UNPIVOT all 33 tips across all 8 dimensions.
-- Each row becomes 33 × 8 = 264 records, one per (dim, tip) pair.
-- rec_val (0 or 1) is retained for aggregation in subsequent steps.
dim_range_base AS (
  SELECT 'nutrition' AS dim,
    CAST(dif_nutrition_mid AS STRING) || ' | ' || CAST(c_val_nutrition_mid AS STRING) AS range_key,
    tip, rec_val
  FROM `northeastgroup4t.health_dataset_generation.train_ready`
  UNPIVOT(rec_val FOR tip IN (
    rec_1,rec_2,rec_3,rec_4,rec_5,rec_6,rec_7,rec_8,rec_9,rec_10,
    rec_11,rec_12,rec_13,rec_14,rec_15,rec_16,rec_17,rec_18,rec_19,rec_20,
    rec_21,rec_22,rec_23,rec_24,rec_25,rec_26,rec_27,rec_28,rec_29,rec_30,
    rec_31,rec_32,rec_33
  ))
  UNION ALL
  SELECT 'obesity',
    CAST(dif_obesity_mid AS STRING) || ' | ' || CAST(c_val_obesity_mid AS STRING),
    tip, rec_val
  FROM `northeastgroup4t.health_dataset_generation.train_ready`
  UNPIVOT(rec_val FOR tip IN (
    rec_1,rec_2,rec_3,rec_4,rec_5,rec_6,rec_7,rec_8,rec_9,rec_10,
    rec_11,rec_12,rec_13,rec_14,rec_15,rec_16,rec_17,rec_18,rec_19,rec_20,
    rec_21,rec_22,rec_23,rec_24,rec_25,rec_26,rec_27,rec_28,rec_29,rec_30,
    rec_31,rec_32,rec_33
  ))
  UNION ALL
  SELECT 'sleep',
    CAST(dif_sleep_mid AS STRING) || ' | ' || CAST(c_val_sleep_mid AS STRING),
    tip, rec_val
  FROM `northeastgroup4t.health_dataset_generation.train_ready`
  UNPIVOT(rec_val FOR tip IN (
    rec_1,rec_2,rec_3,rec_4,rec_5,rec_6,rec_7,rec_8,rec_9,rec_10,
    rec_11,rec_12,rec_13,rec_14,rec_15,rec_16,rec_17,rec_18,rec_19,rec_20,
    rec_21,rec_22,rec_23,rec_24,rec_25,rec_26,rec_27,rec_28,rec_29,rec_30,
    rec_31,rec_32,rec_33
  ))
  UNION ALL
  SELECT 'depression',
    CAST(dif_depression_mid AS STRING) || ' | ' || CAST(c_val_depression_mid AS STRING),
    tip, rec_val
  FROM `northeastgroup4t.health_dataset_generation.train_ready`
  UNPIVOT(rec_val FOR tip IN (
    rec_1,rec_2,rec_3,rec_4,rec_5,rec_6,rec_7,rec_8,rec_9,rec_10,
    rec_11,rec_12,rec_13,rec_14,rec_15,rec_16,rec_17,rec_18,rec_19,rec_20,
    rec_21,rec_22,rec_23,rec_24,rec_25,rec_26,rec_27,rec_28,rec_29,rec_30,
    rec_31,rec_32,rec_33
  ))
  UNION ALL
  SELECT 'wellness',
    CAST(dif_wellness_mid AS STRING) || ' | ' || CAST(c_val_wellness_mid AS STRING),
    tip, rec_val
  FROM `northeastgroup4t.health_dataset_generation.train_ready`
  UNPIVOT(rec_val FOR tip IN (
    rec_1,rec_2,rec_3,rec_4,rec_5,rec_6,rec_7,rec_8,rec_9,rec_10,
    rec_11,rec_12,rec_13,rec_14,rec_15,rec_16,rec_17,rec_18,rec_19,rec_20,
    rec_21,rec_22,rec_23,rec_24,rec_25,rec_26,rec_27,rec_28,rec_29,rec_30,
    rec_31,rec_32,rec_33
  ))
  UNION ALL
  SELECT 'anti_stress',
    CAST(dif_anti_stress_mid AS STRING) || ' | ' || CAST(c_val_anti_stress_mid AS STRING),
    tip, rec_val
  FROM `northeastgroup4t.health_dataset_generation.train_ready`
  UNPIVOT(rec_val FOR tip IN (
    rec_1,rec_2,rec_3,rec_4,rec_5,rec_6,rec_7,rec_8,rec_9,rec_10,
    rec_11,rec_12,rec_13,rec_14,rec_15,rec_16,rec_17,rec_18,rec_19,rec_20,
    rec_21,rec_22,rec_23,rec_24,rec_25,rec_26,rec_27,rec_28,rec_29,rec_30,
    rec_31,rec_32,rec_33
  ))
  UNION ALL
  SELECT 'anti_smoke',
    CAST(dif_anti_smoke_mid AS STRING) || ' | ' || CAST(c_val_anti_smoke_mid AS STRING),
    tip, rec_val
  FROM `northeastgroup4t.health_dataset_generation.train_ready`
  UNPIVOT(rec_val FOR tip IN (
    rec_1,rec_2,rec_3,rec_4,rec_5,rec_6,rec_7,rec_8,rec_9,rec_10,
    rec_11,rec_12,rec_13,rec_14,rec_15,rec_16,rec_17,rec_18,rec_19,rec_20,
    rec_21,rec_22,rec_23,rec_24,rec_25,rec_26,rec_27,rec_28,rec_29,rec_30,
    rec_31,rec_32,rec_33
  ))
  UNION ALL
  SELECT 'movement',
    CAST(dif_movement_mid AS STRING) || ' | ' || CAST(c_val_movement_mid AS STRING),
    tip, rec_val
  FROM `northeastgroup4t.health_dataset_generation.train_ready`
  UNPIVOT(rec_val FOR tip IN (
    rec_1,rec_2,rec_3,rec_4,rec_5,rec_6,rec_7,rec_8,rec_9,rec_10,
    rec_11,rec_12,rec_13,rec_14,rec_15,rec_16,rec_17,rec_18,rec_19,rec_20,
    rec_21,rec_22,rec_23,rec_24,rec_25,rec_26,rec_27,rec_28,rec_29,rec_30,
    rec_31,rec_32,rec_33
  ))
),

-- STEP 2: Denominator — total rows per (dim, range).
-- UNPIVOT expanded the table 33×; divide COUNT back to get original row count.
dim_range_total AS (
  SELECT dim, range_key,
    COUNT(*) / 33 AS range_total
  FROM dim_range_base
  GROUP BY dim, range_key
),

-- STEP 3: Numerator — number of rows where each tip fires, per (dim, range).
-- SUM(rec_val) counts hits correctly since rec_val is binary (0/1).
dim_range_tip_hits AS (
  SELECT dim, range_key, tip,
    SUM(rec_val) AS hits
  FROM dim_range_base
  GROUP BY dim, range_key, tip
),

-- STEP 4: Tip appearance frequency (%) per (dim, range).
dim_range_tip_freq AS (
  SELECT
    h.dim, h.range_key, h.tip,
    h.hits,
    t.range_total,
    ROUND(SAFE_DIVIDE(h.hits, t.range_total) * 100, 4) AS freq_pct
  FROM dim_range_tip_hits h
  JOIN dim_range_total t
    ON h.dim = t.dim AND h.range_key = t.range_key
)

SELECT * FROM dim_range_tip_freq;
