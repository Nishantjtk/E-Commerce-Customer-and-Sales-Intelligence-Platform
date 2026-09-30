"""Build a cohort retention matrix and heatmap from analytics.cohort_retention."""
from __future__ import annotations

import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns

from common import OUTPUT_DIR, ensure_output_directories, query_frame, save_figure

COHORT_SQL = """
WITH cohort_sizes AS (
  SELECT cohort_month, retained_customers AS cohort_size
  FROM analytics.cohort_retention WHERE cohort_index = 0
)
SELECT r.cohort_month, r.purchase_month, r.cohort_index, r.retained_customers, s.cohort_size,
       ROUND(100.0 * r.retained_customers / NULLIF(s.cohort_size, 0), 2) AS retention_rate_pct
FROM analytics.cohort_retention r JOIN cohort_sizes s USING(cohort_month)
ORDER BY r.cohort_month, r.cohort_index;
"""


def main() -> None:
    ensure_output_directories()
    sns.set_theme(style="white")
    cohorts = query_frame(COHORT_SQL)
    cohorts.to_csv(OUTPUT_DIR / "customer_retention_cohorts.csv", index=False)
    cohorts["cohort_month"] = pd.to_datetime(cohorts["cohort_month"]).dt.strftime("%Y-%m")
    matrix = cohorts.pivot(index="cohort_month", columns="cohort_index", values="retention_rate_pct")
    matrix.to_csv(OUTPUT_DIR / "customer_retention_matrix.csv")
    fig, ax = plt.subplots(figsize=(12, 8))
    sns.heatmap(matrix, annot=True, fmt=".1f", cmap="Blues", vmin=0, vmax=100, ax=ax, cbar_kws={"label": "Retention (%)"})
    ax.set(title="Customer Cohort Retention", xlabel="Months since first purchase", ylabel="Cohort month")
    save_figure(fig, "customer_cohort_retention.png")
    plt.close(fig)


if __name__ == "__main__":
    main()
