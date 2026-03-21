-- ============================================================
-- 03_abcd_classification.sql
-- Produces the final ABCD label for each of the 33 base tips.
--
-- Classification rules:
--   A  — activated exclusively by one dimension (bg_freq ≈ 0)
--   B  — modulated by one dimension, present at baseline
--   C  — jointly controlled by two or more dimensions
--   D  — near-constant; appears regardless of all dimension values
--
-- Reads from: tip_ab_typed
-- Output:     tip_abcd_classification
-- ============================================================

CREATE OR REPLACE TABLE
  `northeastgroup4t.health_dataset_generation.tip_abcd_classification`
AS

WITH

-- STEP 9: Compute global appearance rate for each tip (used to identify Type D).
total_rows AS (
  SELECT COUNT(*) AS total
  FROM `northeastgroup4t.health_dataset_generation.train_ready`
),

tip_global_freq AS (
  SELECT
    tip,
    ROUND(SUM(rec_val) / MAX(tr.total) * 100, 2) AS bg_global
  FROM `northeastgroup4t.health_dataset_generation.train_ready`
  UNPIVOT(rec_val FOR tip IN (
    rec_1,rec_2,rec_3,rec_4,rec_5,rec_6,rec_7,rec_8,rec_9,rec_10,
    rec_11,rec_12,rec_13,rec_14,rec_15,rec_16,rec_17,rec_18,rec_19,rec_20,
    rec_21,rec_22,rec_23,rec_24,rec_25,rec_26,rec_27,rec_28,rec_29,rec_30,
    rec_31,rec_32,rec_33
  ))
  CROSS JOIN total_rows tr
  GROUP BY tip
),

-- STEP 10: Assign final ABCD type using cnt_A and cnt_B from tip_ab_typed.
--   D: no dimension influence detected (cnt_A = 0, cnt_B = 0)
--   C: influenced by two or more dimensions (cnt_B ≥ 2, or cnt_B=1 + cnt_A≥1)
--   B: modulated by exactly one dimension (cnt_B = 1, cnt_A = 0)
--   A: exclusively triggered by one dimension (cnt_A ≥ 1, cnt_B = 0)
final_classification AS (
  SELECT
    a.tip,
    CASE
      WHEN a.cnt_A = 0 AND a.cnt_B = 0              THEN 'D'
      WHEN a.cnt_B >= 2                              THEN 'C'
      WHEN a.cnt_B = 1 AND a.cnt_A >= 1             THEN 'C'
      WHEN a.cnt_B = 1 AND a.cnt_A = 0              THEN 'B'
      WHEN a.cnt_A >= 1 AND a.cnt_B = 0             THEN 'A'
      ELSE 'UNCLASSIFIED'
    END AS type,
    CASE
      WHEN a.cnt_A = 0 AND a.cnt_B = 0 THEN []
      WHEN a.cnt_B >= 2
        THEN (SELECT ARRAY_AGG(d.dim ORDER BY d.dim) FROM UNNEST(a.dim_details) d WHERE d.ab_type = 'B')
      WHEN a.cnt_B = 1 AND a.cnt_A >= 1
        THEN (SELECT ARRAY_AGG(d.dim ORDER BY d.dim) FROM UNNEST(a.dim_details) d)
      WHEN a.cnt_B = 1 AND a.cnt_A = 0
        THEN (SELECT ARRAY_AGG(d.dim ORDER BY d.dim) FROM UNNEST(a.dim_details) d WHERE d.ab_type = 'B')
      WHEN a.cnt_A >= 1 AND a.cnt_B = 0
        THEN (SELECT ARRAY_AGG(d.dim ORDER BY d.dim) FROM UNNEST(a.dim_details) d WHERE d.ab_type = 'A')
    END AS triggered_dims,
    CASE
      WHEN a.cnt_B = 1 AND a.cnt_A = 0
        THEN (SELECT d.active_freq FROM UNNEST(a.dim_details) d WHERE d.ab_type = 'B' LIMIT 1)
      WHEN a.cnt_A >= 1 AND a.cnt_B = 0
        THEN (SELECT d.active_freq FROM UNNEST(a.dim_details) d WHERE d.ab_type = 'A' LIMIT 1)
      ELSE NULL
    END AS active_freq,
    CASE
      WHEN a.cnt_A = 0 AND a.cnt_B = 0
        THEN g.bg_global
      WHEN a.cnt_B = 1 AND a.cnt_A = 0
        THEN (SELECT d.bg_freq FROM UNNEST(a.dim_details) d WHERE d.ab_type = 'B' LIMIT 1)
      WHEN a.cnt_A >= 1 AND a.cnt_B = 0
        THEN (SELECT d.bg_freq FROM UNNEST(a.dim_details) d WHERE d.ab_type = 'A' LIMIT 1)
      ELSE NULL
    END AS background_freq
  FROM `northeastgroup4t.health_dataset_generation.tip_ab_typed` a
  LEFT JOIN tip_global_freq g USING (tip)
)

SELECT tip, type, triggered_dims, active_freq, background_freq
FROM final_classification
ORDER BY type, tip;
