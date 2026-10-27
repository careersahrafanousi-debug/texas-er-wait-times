-- Texas ER wait times vs. the rest of the US
-- ED time = OP-18b: median minutes from arrival to leaving the ER (lower is better)
-- LWBS    = OP-22: % of patients who left before being seen (lower is better)
.headers on
.mode column

-- Reusable median: rank each hospital inside its group, then take the middle row(s)
DROP VIEW IF EXISTS v_er_ranked;
CREATE VIEW v_er_ranked AS
SELECT *,
       CASE WHEN state = 'TX' THEN 'Texas' ELSE 'Rest of US' END AS region
FROM er WHERE ed_minutes IS NOT NULL;

-- Q1. Texas vs. rest of US
WITH ranked AS (
    SELECT region, ed_minutes,
           ROW_NUMBER() OVER (PARTITION BY region ORDER BY ed_minutes) AS rn,
           COUNT(*)     OVER (PARTITION BY region)                     AS n
    FROM v_er_ranked
)
SELECT r.region,
       MAX(n)                                   AS hospitals,
       AVG(ed_minutes)                          AS median_ed_minutes,
       (SELECT ROUND(AVG(left_without_seen_pct),1) FROM v_er_ranked v WHERE v.region = r.region) AS avg_lwbs_pct
FROM ranked r
WHERE rn IN ((n + 1) / 2, (n + 2) / 2)
GROUP BY r.region;

-- Q2. Same comparison, but within ER volume tier (busy ERs are slower everywhere)
WITH ranked AS (
    SELECT region, ed_volume, volume_rank, ed_minutes,
           ROW_NUMBER() OVER (PARTITION BY region, ed_volume ORDER BY ed_minutes) AS rn,
           COUNT(*)     OVER (PARTITION BY region, ed_volume)                     AS n
    FROM v_er_ranked WHERE ed_volume IS NOT NULL
)
SELECT ed_volume,
       MAX(CASE WHEN region = 'Texas'      THEN n END) AS tx_hospitals,
       AVG(CASE WHEN region = 'Texas'      THEN ed_minutes END) AS tx_median_min,
       AVG(CASE WHEN region = 'Rest of US' THEN ed_minutes END) AS us_median_min,
       AVG(CASE WHEN region = 'Texas'      THEN ed_minutes END)
     - AVG(CASE WHEN region = 'Rest of US' THEN ed_minutes END) AS tx_minus_us
FROM ranked
WHERE rn IN ((n + 1) / 2, (n + 2) / 2)
GROUP BY ed_volume, volume_rank
ORDER BY volume_rank;

-- Q3. Texas by ownership type
SELECT ownership_group,
       COUNT(*)                          AS hospitals,
       ROUND(AVG(ed_minutes), 0)         AS avg_ed_minutes,
       ROUND(AVG(left_without_seen_pct), 1) AS avg_lwbs_pct,
       ROUND(AVG(volume_rank), 2)        AS avg_volume_rank
FROM v_er_ranked
WHERE region = 'Texas'
GROUP BY ownership_group
ORDER BY avg_ed_minutes DESC;

-- Q4. Does a slow ER line up with lower CMS star ratings? (Texas)
SELECT star_rating,
       COUNT(*)                          AS hospitals,
       ROUND(AVG(ed_minutes), 0)         AS avg_ed_minutes,
       ROUND(AVG(left_without_seen_pct), 1) AS avg_lwbs_pct
FROM v_er_ranked
WHERE region = 'Texas' AND star_rating IS NOT NULL
GROUP BY star_rating ORDER BY star_rating;

-- Q5. LWBS climbs with ED time: bucket all US hospitals by ED minutes
SELECT CASE WHEN ed_minutes < 120 THEN '1) under 2 hrs'
            WHEN ed_minutes < 180 THEN '2) 2-3 hrs'
            WHEN ed_minutes < 240 THEN '3) 3-4 hrs'
            ELSE '4) 4+ hrs' END        AS ed_time_bucket,
       COUNT(*)                          AS hospitals,
       ROUND(AVG(left_without_seen_pct), 1) AS avg_lwbs_pct
FROM v_er_ranked
WHERE left_without_seen_pct IS NOT NULL
GROUP BY 1 ORDER BY 1;

-- Q6. Volume-adjusted outliers: Texas ERs furthest above the US median for their own volume tier
DROP TABLE IF EXISTS peer_median;
CREATE TABLE peer_median AS
WITH ranked AS (
    SELECT ed_volume, ed_minutes,
           ROW_NUMBER() OVER (PARTITION BY ed_volume ORDER BY ed_minutes) AS rn,
           COUNT(*)     OVER (PARTITION BY ed_volume)                     AS n
    FROM v_er_ranked WHERE ed_volume IS NOT NULL
)
SELECT ed_volume, AVG(ed_minutes) AS peer_median_minutes
FROM ranked WHERE rn IN ((n + 1) / 2, (n + 2) / 2)
GROUP BY ed_volume;

DROP TABLE IF EXISTS tx_scorecard;
CREATE TABLE tx_scorecard AS
SELECT v.facility_id, v.facility_name, v.city, v.ownership_group, v.star_rating,
       v.ed_volume, v.ed_minutes, p.peer_median_minutes,
       v.ed_minutes - p.peer_median_minutes AS minutes_vs_peer,
       v.left_without_seen_pct,
       CASE WHEN v.ed_minutes - p.peer_median_minutes >= 60 THEN 'Review'
            WHEN v.ed_minutes - p.peer_median_minutes >= 30 THEN 'Watch'
            ELSE 'OK' END AS flag
FROM v_er_ranked v
JOIN peer_median p USING (ed_volume)
WHERE v.region = 'Texas';

SELECT flag, COUNT(*) AS hospitals FROM tx_scorecard GROUP BY flag;

SELECT facility_name, city, ed_volume, ed_minutes,
       ROUND(minutes_vs_peer) AS min_vs_peer, left_without_seen_pct AS lwbs_pct
FROM tx_scorecard
ORDER BY minutes_vs_peer DESC
LIMIT 10;
