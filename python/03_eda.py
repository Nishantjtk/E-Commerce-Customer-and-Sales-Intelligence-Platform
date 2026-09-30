"""Create reproducible sales and satisfaction EDA extracts and figures."""
from __future__ import annotations

import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns

from common import OUTPUT_DIR, ensure_output_directories, query_frame, save_figure

MONTHLY_SQL = """
SELECT date_trunc('month', order_purchase_timestamp)::date AS month,
       SUM(item_revenue)::numeric(14,2) AS revenue, COUNT(*) AS orders
FROM analytics.order_financials WHERE order_status = 'delivered'
GROUP BY 1 ORDER BY 1;
"""
DELIVERY_SQL = """
SELECT delivery_status, COUNT(*) AS reviewed_orders, AVG(avg_review_score)::numeric(5,2) AS avg_review_score
FROM analytics.delivery_experience WHERE avg_review_score IS NOT NULL
GROUP BY delivery_status ORDER BY delivery_status;
"""


def main() -> None:
    ensure_output_directories()
    sns.set_theme(style="whitegrid")
    monthly = query_frame(MONTHLY_SQL)
    monthly["month"] = pd.to_datetime(monthly["month"])
    monthly.to_csv(OUTPUT_DIR / "monthly_sales_trend.csv", index=False)
    fig, ax = plt.subplots(figsize=(11, 5))
    sns.lineplot(data=monthly, x="month", y="revenue", marker="o", ax=ax)
    ax.set(title="Delivered Item Revenue by Month", xlabel="Purchase month", ylabel="Revenue (BRL)")
    save_figure(fig, "monthly_revenue_trend.png")
    plt.close(fig)

    delivery = query_frame(DELIVERY_SQL)
    delivery.to_csv(OUTPUT_DIR / "delivery_review_summary.csv", index=False)
    fig, ax = plt.subplots(figsize=(8, 5))
    sns.barplot(data=delivery, x="delivery_status", y="avg_review_score", ax=ax, color="#2a6fbb")
    ax.set(title="Review Score by Delivery Status", xlabel="Delivery status", ylabel="Average review score", ylim=(0, 5))
    save_figure(fig, "review_score_by_delivery_status.png")
    plt.close(fig)


if __name__ == "__main__":
    main()
