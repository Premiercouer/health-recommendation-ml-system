-- ============================================================
-- sample_model_training.sql
-- Representative example of the BigQuery ML training configuration
-- used across all 18 BOOSTED_TREE_CLASSIFIER models.
--
-- All 18 models share identical hyperparameters and the same
-- 16-feature input space. The only variation is the label column:
--   - Y1 models (10): binary classification (0 / 1)
--   - Y2 models (8):  multi-class classification (imp / acc / not)
--
-- See README for the full model inventory and performance results.
-- ============================================================

CREATE OR REPLACE MODEL `northeastgroup4t.health_models.model_nutrition_tips`
OPTIONS (
  model_type         = 'BOOSTED_TREE_CLASSIFIER',
  input_label_cols   = ['nutrition_tips'],
  data_split_method  = 'AUTO_SPLIT',
  -- Tree structure
  max_iterations     = 40,
  max_tree_depth     = 4,
  num_parallel_tree  = 1,
  early_stop         = TRUE,
  -- Regularization
  min_split_loss     = 0.0,
  l1_reg             = 0.0,
  l2_reg             = 1.0,
  -- Sampling
  subsample          = 0.8,
  colsample_bytree   = 0.8
) AS
SELECT
  -- 16 input features: 8 difference indicators + 8 current value indicators
  dif_nutrition_mid,    dif_obesity_mid,    dif_sleep_mid,      dif_depression_mid,
  dif_wellness_mid,     dif_anti_stress_mid,dif_anti_smoke_mid, dif_movement_mid,
  c_val_nutrition_mid,  c_val_obesity_mid,  c_val_sleep_mid,    c_val_depression_mid,
  c_val_wellness_mid,   c_val_anti_stress_mid, c_val_anti_smoke_mid, c_val_movement_mid,
  -- Label: replace with the target column for each model
  nutrition_tips
FROM `northeastgroup4t.health_dataset_generation.train_ready_v2`;
