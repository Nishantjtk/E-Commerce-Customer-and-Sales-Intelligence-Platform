"""Export and visualize the database-certified RFM customer segments."""
from __future__ import annotations

import matplotlib.pyplot as plt
import seaborn as sns

from common import OUTPUT_DIR, ensure_output_directories, query_frame, save_figure

RFM_SQL = """
SELECT customer_unique_id, last_purchase_date, recency_days, frequency, monetary,
       recency_score, frequency_score, monetary_score, rfm_score, customer_segment
FROM analytics.customer_rfm;
"""


def main() -> None:
    ensure_output_directories()
    sns.set_theme(style="whitegrid")
    rfm = query_frame(RFM_SQL)
    rfm.to_csv(OUTPUT_DIR / "customer_rfm_segments.csv", index=False)
    summary = rfm.groupby("customer_segment", as_index=False).agg(
        customers=("customer_unique_id", "nunique"), revenue=("monetary", "sum")
    ).sort_values("revenue", ascending=False)
    summary.to_csv(OUTPUT_DIR / "customer_rfm_segment_summary.csv", index=False)
    fig, ax = plt.subplots(figsize=(10, 6))
    sns.barplot(data=summary, y="customer_segment", x="revenue", ax=ax, color="#117864")
    ax.set(title="Historical Delivered Revenue by RFM Segment", xlabel="Revenue (BRL)", ylabel="")
    save_figure(fig, "rfm_segment_revenue.png")
    plt.close(fig)


if __name__ == "__main__":
    main()
