-- Build one clean row per hospital with the ED measures side by side.
-- CMS stores "Not Available" as text, so those become NULL here.

DROP TABLE IF EXISTS hospital;
CREATE TABLE hospital AS
SELECT
    "Facility ID"            AS facility_id,
    "Facility Name"          AS facility_name,
    "City/Town"              AS city,
    State                    AS state,
    "Hospital Type"          AS hospital_type,
    CASE
        WHEN "Hospital Ownership" LIKE 'Voluntary non-profit%' THEN 'Non-profit'
        WHEN "Hospital Ownership" = 'Proprietary'              THEN 'For-profit'
        WHEN "Hospital Ownership" LIKE 'Government%'           THEN 'Government'
        ELSE 'Other'
    END                      AS ownership_group,
    "Emergency Services"     AS has_ed,
    CASE WHEN "Hospital overall rating" GLOB '[1-5]'
         THEN CAST("Hospital overall rating" AS INTEGER) END AS star_rating
FROM raw_hospital;

DROP TABLE IF EXISTS ed_measures;
CREATE TABLE ed_measures AS
SELECT
    "Facility ID" AS facility_id,
    MAX(CASE WHEN "Measure ID" = 'OP_18b' AND Score GLOB '[0-9]*' THEN CAST(Score AS INTEGER) END) AS ed_minutes,
    MAX(CASE WHEN "Measure ID" = 'OP_18c' AND Score GLOB '[0-9]*' THEN CAST(Score AS INTEGER) END) AS ed_minutes_psych,
    MAX(CASE WHEN "Measure ID" = 'OP_22'  AND Score GLOB '[0-9]*' THEN CAST(Score AS INTEGER) END) AS left_without_seen_pct,
    MAX(CASE WHEN "Measure ID" = 'EDV'    AND Score <> 'Not Available' THEN Score END)            AS ed_volume
FROM raw_ed
GROUP BY "Facility ID";

-- Analysis table: acute care / critical access hospitals that run an ER
DROP TABLE IF EXISTS er;
CREATE TABLE er AS
SELECT h.*, e.ed_minutes, e.ed_minutes_psych, e.left_without_seen_pct, e.ed_volume,
       CASE e.ed_volume WHEN 'low' THEN 1 WHEN 'medium' THEN 2
                        WHEN 'high' THEN 3 WHEN 'very high' THEN 4 END AS volume_rank
FROM hospital h
JOIN ed_measures e USING (facility_id)
WHERE h.has_ed = 'Yes'
  AND h.hospital_type IN ('Acute Care Hospitals', 'Critical Access Hospitals');
