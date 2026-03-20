CREATE OR REPLACE TABLE
`northeastgroup4t.health_dataset_generation.base_tips_raw`
AS

WITH sentences AS (
SELECT
  TRIM(sentence) AS sentence
FROM
  `northeastgroup4t.health_dataset_generation.data_generated_with_recom`,
  UNNEST(SPLIT(recommendations,'.')) AS sentence
)

SELECT DISTINCT sentence
FROM sentences
WHERE sentence IS NOT NULL
AND sentence != ""
