SELECT customer_state, COUNT(*) FILTER (WHERE delivery_days IS NOT NULL) AS delivered_orders,
       ROUND(AVG(delivery_days),2) AS avg_delivery_days,
       ROUND(100.0 * AVG(is_late_delivery),2) AS late_delivery_rate_pct,
       ROUND(AVG(avg_review_score),2) AS avg_review_score
FROM analytics.delivery_experience GROUP BY customer_state ORDER BY late_delivery_rate_pct DESC NULLS LAST;
