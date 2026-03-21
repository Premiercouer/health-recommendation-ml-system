-- ============================================================
-- 02_variance_abtype.sql
-- Identifies which tips are statistically influenced by each
-- dimension using frequency variance, then classifies each
-- (dim, tip) pair as Type A or Type B.
--
-- Reads from: tip_freq_by_dim_range
-- Output:     tip_ab_typed
-- ============================================================

CREATE OR REPLACE TABLE
  `northeastgroup4t.health_dataset_generation.tip_ab_typed`
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

all_dim_ranges AS (
  SELECT DISTINCT dim, range_key
  FROM `northeastgroup4t.health_dataset_generation.tip_freq_by_dim_range`
),

-- STEP 5: Fill all (dim × range × tip) combinations with 0 where no data exists.
-- Without this, tips that never appear in a range are silently absent,
-- which underestimates variance and masks truly dimension-driven tips.
dim_range_tip_full AS (
  SELECT
    dr.dim, dr.range_key, t.tip,
    COALESCE(f.freq_pct, 0) AS freq_pct
  FROM all_dim_ranges dr
  CROSS JOIN all_tips t
  LEFT JOIN `northeastgroup4t.health_dataset_generation.tip_freq_by_dim_range` f
    ON dr.dim = f.dim
    AND dr.range_key = f.range_key
    AND t.tip = f.tip
),

-- STEP 6: Compute per-(dim, tip) variance across all input ranges.
-- High variance indicates that tip frequency changes significantly
-- as the dimension value changes — a signal of dimension influence.
dim_tip_with_avg AS (
  SELECT
    dim, tip, range_key, freq_pct,
    AVG(freq_pct) OVER (PARTITION BY dim, tip) AS avg_freq,
    (AVG(freq_pct * freq_pct) OVER (PARTITION BY dim, tip))
      - POW(AVG(freq_pct) OVER (PARTITION BY dim, tip), 2) AS variance
  FROM dim_range_tip_full
),

-- Keep only (dim, tip) pairs where variance > 10.
-- Summarise into active_freq (high-risk range avg) and bg_freq (baseline avg).
dim_tip_profiles AS (
  SELECT
    dim, tip,
    MAX(variance)    AS variance,
    MAX(avg_freq)    AS avg_freq,
    ROUND(AVG(CASE WHEN freq_pct > avg_freq + 5 THEN freq_pct END), 2) AS active_freq,
    ROUND(AVG(CASE WHEN freq_pct < avg_freq     THEN freq_pct END), 2) AS bg_freq
  FROM dim_tip_with_avg
  WHERE variance > 10
  GROUP BY dim, tip
),

-- STEP 7: Assign A/B type to each (dim, tip) pair.
-- Type A: tip is essentially absent at baseline (bg_freq ≤ 5)
--         but fires strongly in high-risk range (active_freq ≥ 30).
-- Type B: tip appears at baseline but is amplified in high-risk range.
tip_dim_typed AS (
  SELECT
    tip, dim, active_freq, bg_freq,
    CASE
      WHEN bg_freq <= 5 AND active_freq >= 30 THEN 'A'
      WHEN active_freq > bg_freq AND bg_freq > 0 THEN 'B'
      ELSE NULL
    END AS ab_type
  FROM dim_tip_profiles
  WHERE (bg_freq <= 5 AND active_freq >= 30)
     OR (active_freq > bg_freq AND bg_freq > 0)
),

-- STEP 8: Aggregate per-tip A/B counts and dimension details.
-- cnt_A / cnt_B drive the final ABCD classification in the next step.
tip_ab_counts AS (
  SELECT
    tip,
    COUNTIF(ab_type = 'A') AS cnt_A,
    COUNTIF(ab_type = 'B') AS cnt_B,
    ARRAY_AGG(STRUCT(dim, ab_type, active_freq, bg_freq) ORDER BY dim) AS dim_details
  FROM tip_dim_typed
  GROUP BY tip
)

SELECT
  t.tip,
  COALESCE(c.cnt_A, 0) AS cnt_A,
  COALESCE(c.cnt_B, 0) AS cnt_B,
  c.dim_details
FROM all_tips t
LEFT JOIN tip_ab_counts c USING (tip);
