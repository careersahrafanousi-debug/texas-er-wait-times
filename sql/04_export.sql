-- Export tables for Tableau
.headers on
.mode csv
.output output/er_all_hospitals.csv
SELECT facility_id, facility_name, city, state,
       CASE WHEN state = 'TX' THEN 'Texas' ELSE 'Rest of US' END AS region,
       hospital_type, ownership_group, star_rating, ed_volume, volume_rank,
       ed_minutes, ed_minutes_psych, left_without_seen_pct
FROM er;
.output output/tx_er_scorecard.csv
SELECT * FROM tx_scorecard ORDER BY minutes_vs_peer DESC;
.output stdout
