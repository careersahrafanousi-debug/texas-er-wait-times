# Tableau dashboard

Data source: `output/er_all_hospitals.csv` and `output/tx_er_scorecard.csv`

**Sheets**
1. **TX vs US by volume** - Columns: `Ed Volume` (sort: low, medium, high, very high). Rows: `MEDIAN(Ed Minutes)`. Color: `Region`.
2. **Texas map** - Use the scorecard file. Geographic role on `City` (State = TX). Color: `Minutes Vs Peer` (diverging, center 0). Size: `Ed Minutes`. Tooltip: name, volume, LWBS %.
3. **Walkouts vs. ER time** - Scatter: `Ed Minutes` (x) vs `Left Without Seen Pct` (y), filter Region. Add a trend line.
4. **Scorecard table** - `Facility Name`, `Ed Volume`, `Ed Minutes`, `Peer Median Minutes`, `Minutes Vs Peer`, `Flag`. Color `Flag`: Review = red, Watch = orange, OK = gray.

**Dashboard:** KPI tiles on top (TX median 137.5 min, US median 149 min, 45 hospitals flagged), then sheets 1 and 2 side by side, 4 underneath. Filters: Ownership Group, Ed Volume.

Published version: _add your Tableau Public link here_
