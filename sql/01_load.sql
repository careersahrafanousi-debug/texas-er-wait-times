-- Load the two CMS files into SQLite.
-- Run from the repo root:  sqlite3 er.db < sql/01_load.sql
.mode csv
DROP TABLE IF EXISTS raw_hospital;
DROP TABLE IF EXISTS raw_ed;
.import data/cms_hospital_info.csv raw_hospital
.import data/cms_ed_measures.csv raw_ed
