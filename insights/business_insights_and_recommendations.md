# Business Insights and Recommendations

## Executive summary

The delivered-order baseline contains 96,478 orders and R$13.22M in item revenue across 93,358 unique customers. Customer satisfaction is strongly associated with delivery execution: on-time/early delivered orders average **4.29/5**, compared with **2.57/5** for late orders.

## Findings

- **Delivery is the highest-priority experience lever.** There are 7,662 late reviewed orders; their average review score is 1.72 points below on-time/early orders.
- **At-risk customers hold the largest segment revenue pool.** The 22,522 at-risk customers contributed R$4.70M historically, ahead of Champions/VIP customers (R$4.22M).
- **Champions/VIP customers are a clear protection segment.** 15,648 customers have generated R$4.22M and should receive service-recovery priority where affected by late delivery.
- **Revenue is concentrated in a small group of categories.** Health & beauty leads at R$1.41M, followed by watches & gifts (R$1.26M), bed bath table (R$1.23M), sports & leisure (R$1.12M), and computers & accessories (R$1.03M).

## Risks

- Late deliveries create a material satisfaction risk and likely suppress repeat purchase.
- The `Not delivered` group has a 1.75/5 average review score; it needs distinct exception handling rather than inclusion in operational delivery averages.
- Eight orders labelled delivered lack a final customer-delivery timestamp. They should be excluded from duration KPIs and investigated with the source owner.

## Recommendations

1. Prioritize logistics root-cause analysis by seller state, customer state, and category using `sql/08_delivery_customer_experience.sql`; set an alert for late-delivery rate deterioration.
2. Run a targeted retention campaign for the at-risk segment, prioritizing customers with high monetary value and a recent service failure.
3. Establish a VIP recovery workflow for Champions affected by late delivery: proactive delivery updates, expedited resolution, and post-resolution feedback.
4. Use the top five categories as the first category-level operating review, combining revenue, late-delivery rate, and review score before investing further in demand growth.

All figures are calculated from the loaded Olist extract. They describe historical associations, not causal effects.
