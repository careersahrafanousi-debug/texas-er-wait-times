# Charts for the README. Reads the CSVs produced by sql/04_export.sql
import sqlite3, pandas as pd, matplotlib.pyplot as plt
plt.rcParams.update({"font.size":11,"axes.spines.top":False,"axes.spines.right":False,"axes.titleweight":"bold","axes.titlelocation":"left"})
BLUE, ORANGE = "#4E79A7", "#F28E2B"
df = pd.read_csv("output/er_all_hospitals.csv").dropna(subset=["ed_minutes","ed_volume"])
order = ["low","medium","high","very high"]
med = df.groupby(["ed_volume","region"])["ed_minutes"].median().unstack().reindex(order)
ax = med[["Rest of US","Texas"]].plot.bar(color=[ORANGE, BLUE], figsize=(8,4.5), rot=0, width=0.75)
ax.set_title("Median ER time by ER volume: Texas vs. rest of US")
ax.set_xlabel("CMS ER volume tier"); ax.set_ylabel("Median minutes in ER (OP-18b)")
for c in ax.containers: ax.bar_label(c, fmt="%.0f", fontsize=9)
ax.legend(frameon=False); plt.tight_layout(); plt.savefig("images/tx_vs_us_by_volume.png", dpi=150); plt.close()

d = pd.read_csv("output/er_all_hospitals.csv").dropna(subset=["ed_minutes","left_without_seen_pct"])
d["bucket"] = pd.cut(d.ed_minutes, [0,120,180,240,999], labels=["Under 2 hrs","2-3 hrs","3-4 hrs","4+ hrs"])
g = d.groupby("bucket", observed=True)["left_without_seen_pct"].mean()
ax = g.plot.bar(color=BLUE, figsize=(7,4.2), rot=0)
ax.set_title("Patients leaving before being seen rise with ER time")
ax.set_xlabel("Hospital median ER time"); ax.set_ylabel("Avg % left without being seen (OP-22)")
ax.bar_label(ax.containers[0], fmt="%.1f%%"); plt.tight_layout(); plt.savefig("images/lwbs_by_er_time.png", dpi=150)
