"""Quantify delivery performance and customer satisfaction at category level."""
from __future__ import annotations

import matplotlib.pyplot as plt
import seaborn as sns

from common import OUTPUT_DIR, ensure_output_directories, query_frame, save_figure

EXPERIENCE_SQL = """
SELECT category_name, delivered_orders, revenue, avg_delivery_days,
       late_delivery_rate, avg_review_score
FROM analytics.category_experience
WHERE delivered_orders >= 100
ORDER BY revenue DESC;
"""


def main() -> None:
    ensure_output_directories()
    sns.set_theme(style="whitegrid")
    experience = query_frame(EXPERIENCE_SQL)
    experience.to_csv(OUTPUT_DIR / "category_customer_experience.csv", index=False)
    fig, ax = plt.subplots(figsize=(10, 7))
    sns.scatterplot(data=experience, x="late_delivery_rate", y="avg_review_score", size="revenue",
                    sizes=(30, 500), hue="avg_delivery_days", palette="viridis", ax=ax)
    ax.set(title="Category Delivery Risk and Customer Satisfaction", xlabel="Late delivery rate", ylabel="Average review score", ylim=(0, 5))
    save_figure(fig, "category_delivery_satisfaction_risk.png")
    plt.close(fig)


if __name__ == "__main__":
    main()
