-- Quick data checks before analysis
.headers on
.mode column

-- 1. One row per hospital?
SELECT COUNT(*) AS rows, COUNT(DISTINCT facility_id) AS hospitals FROM er;

-- 2. How much of each measure is missing? (CMS suppresses small samples)
SELECT state = 'TX' AS is_texas,
       COUNT(*)                                       AS hospitals,
       SUM(ed_minutes IS NULL)                        AS missing_ed_minutes,
       ROUND(100.0 * SUM(ed_minutes IS NULL) / COUNT(*), 1) AS pct_missing,
       SUM(left_without_seen_pct IS NULL)             AS missing_lwbs,
       SUM(ed_volume IS NULL)                         AS missing_volume
FROM er GROUP BY 1;

-- 3. Any impossible values?
SELECT MIN(ed_minutes), MAX(ed_minutes), MIN(left_without_seen_pct), MAX(left_without_seen_pct) FROM er;
